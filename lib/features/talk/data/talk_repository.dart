import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../config/feature_flags.dart';
import '../../../config/firebase/firebase_configuration.dart';
import '../../chat/data/repositories/chat_repository.dart';
import 'talk_thread.dart';

/// Streams the Talk inbox from Firestore via [ChatRepository.watchUserChats].
///
/// Signed-out preview mode still uses [curatedTalkThreads] so the marketing
/// screens can render without an account. Authenticated mode never injects
/// demo conversations: an empty inbox is a real empty inbox.
class TalkRepository {
  TalkRepository({FirebaseFirestore? firestore, ChatRepository? chatRepository})
      : _chatRepository =
            chatRepository ?? ChatRepository(firestore: firestore);

  final ChatRepository _chatRepository;

  Stream<List<TalkThread>> streamThreads({String? uid}) async* {
    if (!FirebaseConfiguration.isAvailable || uid == null || uid.isEmpty) {
      yield AppFeatureFlags.signedOutPreviews
          ? curatedTalkThreads
          : const <TalkThread>[];
      return;
    }

    try {
      yield* _chatRepository.watchUserChats(uid);
    } catch (_) {
      yield const <TalkThread>[];
    }
  }
}
