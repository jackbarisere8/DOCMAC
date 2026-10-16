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

  Stream<List<TalkThread>> streamThreads({String? uid}) async* {
    // Yield curated fallback threads immediately so the inbox displays in 0ms
    // without frozen skeleton screens while Firestore establishes connection.
    yield curatedTalkThreads;

    if (!FirebaseConfiguration.isAvailable || uid == null || uid.isEmpty) {
      return;
    }

    try {
      await for (final threads in _chatRepository.watchUserChats(uid)) {
        if (threads.isNotEmpty) {
          yield threads;
        } else {
          yield curatedTalkThreads;
        }
      }
    } catch (_) {
      yield curatedTalkThreads;
    }
  }
}
