import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../config/firebase/firebase_configuration.dart';
import '../../chat/data/repositories/chat_repository.dart';
import 'talk_thread.dart';

/// Streams the Talk inbox from Firestore via [ChatRepository.watchUserChats],
/// falling back to curated preview threads when signed out or offline.
class TalkRepository {
  TalkRepository({FirebaseFirestore? firestore, ChatRepository? chatRepository})
      : _chatRepository =
            chatRepository ?? ChatRepository(firestore: firestore);

  final ChatRepository _chatRepository;

  Stream<List<TalkThread>> streamThreads({String? uid}) {
    if (!FirebaseConfiguration.isAvailable || uid == null || uid.isEmpty) {
      return Stream.value(curatedTalkThreads);
    }
    try {
      return _chatRepository
          .watchUserChats(uid)
          .handleError((Object _) => curatedTalkThreads);
    } catch (_) {
      return Stream.value(curatedTalkThreads);
    }
  }
}
