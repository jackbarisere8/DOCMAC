import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/firebase/firebase_configuration.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../data/talk_repository.dart';
import '../../data/talk_thread.dart';

export '../../../chat/presentation/providers/chat_providers.dart'
    show chatRepositoryProvider, chatMessagesProvider, curatedChatMessages;

final talkRepositoryProvider =
    Provider<TalkRepository>((ref) => TalkRepository(
          chatRepository: ref.watch(chatRepositoryProvider),
        ));

/// Inbox threads for the Talk tab.
///
/// Watches the signed-in user so sign-in/out re-streams automatically.
/// Signed out (or Firebase unconfigured) yields [curatedTalkThreads] as a
/// preview state; signed in streams `chats` where `participantIds`
/// contains the uid via [ChatRepository.watchUserChats].
final talkThreadsProvider = StreamProvider<List<TalkThread>>((ref) {
  try {
    final user = ref.watch(currentUserProvider);
    if (!FirebaseConfiguration.isAvailable || user == null) {
      return Stream.value(curatedTalkThreads);
    }
    final repository = ref.watch(chatRepositoryProvider);
    return repository
        .watchUserChats(user.id)
        .handleError((Object _) => curatedTalkThreads);
  } catch (_) {
    return Stream.value(curatedTalkThreads);
  }
});
