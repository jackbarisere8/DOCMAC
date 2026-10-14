import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../config/firebase/firebase_configuration.dart';
import 'talk_thread.dart';

/// Streams the Talk inbox from Firestore, falling back to curated preview
/// threads when signed out or offline.
///
/// Firestore shape (see `firestore.rules`): `chats/{chatId}` must contain
/// `participantIds: [uid, ...]`. Optional display fields (`name`, `title`,
/// `lastMessage`, `preview`, `unreadCount`, `isGroup`) are read defensively;
/// missing fields fall back to the document id so a partially written chat
/// never crashes the inbox.
class TalkRepository {
  TalkRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  Stream<List<TalkThread>> streamThreads({String? uid}) {
    final firestore = _firestore ?? FirebaseFirestore.instance;
    if (!FirebaseConfiguration.isAvailable || uid == null || uid.isEmpty) {
      return Stream.value(curatedTalkThreads);
    }
    try {
      return firestore
          .collection('chats')
          .where('participantIds', arrayContains: uid)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(_fromDoc).toList())
          .handleError((Object _) => curatedTalkThreads);
    } catch (_) {
      return Stream.value(curatedTalkThreads);
    }
  }

  TalkThread _fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final participantIds = data['participantIds'];
    final participantCount =
        participantIds is List ? participantIds.length : 0;
    final name = (data['name'] ?? data['title'] ?? doc.id).toString();
    final preview = (data['lastMessage'] ?? data['preview'] ?? 'Wave back to begin a conversation')
        .toString();
    final unread = data['unreadCount'] is int
        ? data['unreadCount'] as int
        : 0;
    final isGroup =
        data['isGroup'] is bool ? data['isGroup'] as bool : participantCount > 2;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final time = _readTime(data['lastCreatedAt'] ?? data['updatedAt']);
    return TalkThread(
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
