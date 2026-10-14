import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/talk_repository.dart';
import '../../data/talk_thread.dart';

export '../../../chat/presentation/providers/chat_providers.dart'
    show chatRepositoryProvider, chatMessagesProvider, curatedChatMessages;

final talkRepositoryProvider =
    Provider<TalkRepository>((ref) => TalkRepository());

/// Inbox threads for the Talk tab.
///
/// Watches the signed-in user so sign-in/out re-streams automatically.
/// Signed out (or Firebase unconfigured) yields [curatedTalkThreads] as a
/// preview state; signed in streams `chats` where `participantIds`
/// contains the uid (see `firestore.rules` chat-member rule).
final talkThreadsProvider = StreamProvider<List<TalkThread>>((ref) {
  final user = ref.watch(currentUserProvider);
  final repository = ref.watch(talkRepositoryProvider);
  return repository.streamThreads(uid: user?.id);
});
