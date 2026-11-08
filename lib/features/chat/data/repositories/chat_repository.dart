import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/chat_message.dart';
import '../models/chat_thread.dart';

/// Result of resolving a 1:1 conversation with the server.
class DirectChat {
  const DirectChat({
    required this.chatId,
    required this.peerUid,
    required this.peerName,
    this.peerHandle,
  });

  final String chatId;
  final String peerUid;
  final String peerName;
  final String? peerHandle;
}

class ChatRepository {
  ChatRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore,
        _functions = functions;

  /// Null in tests/preview until a real Firestore is supplied. Resolved
  /// lazily so constructing the repository never touches
  /// `FirebaseFirestore.instance` (which throws without Firebase init).
  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseFunctions get _callableClient =>
      _functions ?? FirebaseFunctions.instance;

  /// Deterministic chat id for a 1:1 conversation. Both participants compute
  /// the same value because the UIDs are sorted before being joined.
  static String directChatId(String uidA, String uidB) {
    final ids = [uidA, uidB]..sort();
    return 'direct_${ids[0]}__${ids[1]}';
  }

  /// Resolves a peer (by UID or @handle) and returns the canonical chat.
  /// Chat creation is a server operation so membership documents cannot be
  /// forged by either client.
  Future<DirectChat> ensureDirectChat({
    String? peerUid,
    String? peerHandle,
    String? peerName,
  }) async {
    final payload = <String, dynamic>{
      if (peerUid != null && peerUid.trim().isNotEmpty)
        'peerUid': peerUid.trim(),
      if (peerHandle != null && peerHandle.trim().isNotEmpty)
        'peerHandle': peerHandle.trim(),
      if (peerName != null && peerName.trim().isNotEmpty)
        'peerName': peerName.trim(),
    };

    final result = await _callableClient
        .httpsCallable('ensureDirectChat')
        .call<dynamic>(payload);

    final raw = result.data;
    final data =
        raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};
    final chatId = data['chatId'];
    if (chatId is! String || chatId.isEmpty) {
      throw StateError('The server did not return a conversation.');
    }

    return DirectChat(
      chatId: chatId,
      peerUid:
          data['peerUid'] is String ? data['peerUid'] as String : peerUid ?? '',
      peerName: data['peerName'] is String
          ? data['peerName'] as String
          : peerName ?? 'Docmac member',
      peerHandle: data['peerHandle'] is String
          ? data['peerHandle'] as String
          : peerHandle,
    );
  }

  /// Streams the newest 50 messages in chronological order. Ordering newest
  /// first keeps the limit anchored to the live end of busy conversations.
  Stream<List<ChatMessage>> streamMessages(String chatId) {
    if (chatId.isEmpty) return Stream.value(const []);
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.reversed
            .map((doc) => ChatMessage.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Writes the message and refreshes the conversation preview atomically.
  /// If the member has no write access the batch fails as a whole, so an
  /// orphan message can never be left behind.
  Future<void> sendMessage({
    required String chatId,
    required ChatMessage message,
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc(message.id);
    final text = message.text.trim();
    final preview = text.length <= 140 ? text : '${text.substring(0, 140)}…';

    final batch = _db.batch();
    batch.set(messageRef, message.toMap());
    batch.update(chatRef, {
      'lastMessage': preview,
      'lastMessageAt': Timestamp.fromDate(message.createdAt),
      'lastSenderId': message.senderId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Marks a peer message read. Rules permit clients to flip only `isRead`
  /// (see `firestore.rules` messages/update); sender, body, timestamp and
  /// chat identity stay immutable and deletes stay denied.
  Future<void> markAsRead({
    required String chatId,
    required String messageId,
  }) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  /// Streams all chats where [uid] is a participant, newest activity first.
  Stream<List<ChatThread>> watchUserChats(String uid) {
    if (uid.isEmpty) return Stream.value(const []);
    return _db
        .collection('chats')
        .where('participantIds', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => _fromDoc(doc, uid)).toList());
  }

  /// Marks the entire chat as read for [uid].
  Future<void> markChatRead(String chatId, String uid) async {
    if (chatId.isEmpty) return;
    await _db.collection('chats').doc(chatId).update({
      'unreadCount': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  ChatThread _fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String uid,
  ) {
    final data = doc.data();
    final participants = data['participantIds'] is List
        ? List<String>.from(data['participantIds'] as List)
        : const <String>[];
    final isGroup = data['isGroup'] == true ||
        data['type'] == 'group' ||
        participants.length > 2;
    String? peerUid;
    if (!isGroup) {
      for (final participant in participants) {
        if (participant != uid) {
          peerUid = participant;
          break;
        }
      }
    }

    final names = data['participantNames'] is Map
        ? Map<String, dynamic>.from(data['participantNames'] as Map)
        : const <String, dynamic>{};
    final handles = data['participantHandles'] is Map
        ? Map<String, dynamic>.from(data['participantHandles'] as Map)
        : const <String, dynamic>{};

    final fallbackName =
        (data['name'] ?? data['title'] ?? 'Docmac member').toString();
    final name = isGroup
        ? fallbackName
        : (peerUid != null && names[peerUid] is String
            ? names[peerUid] as String
            : fallbackName);
    final preview = (data['lastMessage'] ?? '').toString();
    final unread = data['unreadCount'] is int ? data['unreadCount'] as int : 0;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final time = _readTime(data['lastMessageAt'] ?? data['updatedAt']);

    return ChatThread(
      id: doc.id,
      chatId: doc.id,
      name: name,
      initial: initial,
      preview:
          preview.isNotEmpty ? preview : 'No messages yet. Say hello first.',
      time: time,
      peerUid: peerUid,
      peerHandle: peerUid != null && handles[peerUid] is String
          ? handles[peerUid] as String
          : null,
      unread: unread,
      isGroup: isGroup,
    );
  }

  String _readTime(Object? value) {
    if (value is Timestamp) {
      final date = value.toDate().toLocal();
      final now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
        final minute = date.minute.toString().padLeft(2, '0');
        final period = date.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute $period';
      }
      return '${date.day}/${date.month}';
    }
    return '';
  }
}
