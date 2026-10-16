import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';

class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  /// Null in tests/preview until a real Firestore is supplied. Resolved
  /// lazily so constructing the repository never touches
  /// `FirebaseFirestore.instance` (which throws without Firebase init).
  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> sendMessage(
      {required String chatId, required ChatMessage message}) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
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

  /// Streams all chat threads where [uid] is a participant.
  Stream<List<ChatThread>> watchUserChats(String uid) {
    if (uid.isEmpty) return Stream.value(const []);
    return _db
        .collection('chats')
        .where('participantIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  /// Creates a direct 1:1 chat between [currentUid] and [peerUid],
  /// or returns an existing one if it already exists.
  Future<String> createOrGetDirectChat({
    required String currentUid,
    required String peerUid,
    required String peerName,
  }) async {
    final query = await _db
        .collection('chats')
        .where('participantIds', arrayContains: currentUid)
        .get();

    for (final doc in query.docs) {
      final data = doc.data();
      final participants =
          List<String>.from(data['participantIds'] ?? const []);
      final isGroup = data['isGroup'] == true;
      if (!isGroup && participants.contains(peerUid)) {
        return doc.id;
      }
    }

    final docRef = _db.collection('chats').doc();
    await docRef.set({
      'id': docRef.id,
      'name': peerName,
      'participantIds': [currentUid, peerUid],
      'isGroup': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'unreadCount': 0,
    });
    return docRef.id;
  }

  /// Marks the entire chat as read for [uid].
  Future<void> markChatRead(String chatId, String uid) async {
    await _db.collection('chats').doc(chatId).update({
      'unreadCount': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }).catchError((_) => null);
  }

  ChatThread _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final participantIds = data['participantIds'];
    final participantCount =
        participantIds is List ? participantIds.length : 0;
    final name = (data['name'] ?? data['title'] ?? doc.id).toString();
    final preview = (data['lastMessage'] ??
            data['preview'] ??
            'Wave back to begin a conversation')
        .toString();
    final unread =
        data['unreadCount'] is int ? data['unreadCount'] as int : 0;
    final isGroup =
        data['isGroup'] is bool ? data['isGroup'] as bool : participantCount > 2;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final time = _readTime(data['lastCreatedAt'] ?? data['updatedAt']);
    return ChatThread(
      id: doc.id,
      chatId: doc.id,
      name: name,
      initial: initial,
      preview: preview,
      time: time,
      unread: unread,
      isGroup: isGroup,
    );
  }

  String _readTime(Object? value) {
    if (value is Timestamp) {
      final date = value.toDate().toLocal();
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }
    return 'Recently';
  }
}
