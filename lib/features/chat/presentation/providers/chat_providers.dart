import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/firebase/firebase_configuration.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';

final chatRepositoryProvider =
    Provider<ChatRepository>((ref) => ChatRepository());

/// Preview inbox shown when signed out or Firebase is unconfigured, so the
/// chat surface still renders instead of a blank spinner. Sender `preview-me`
/// is treated as mine only in preview mode; authenticated mode compares
/// [ChatMessage.senderId] to the uid.
List<ChatMessage> curatedChatMessages(String chatId) {
  final now = DateTime.now();
  return [
    ChatMessage(
      id: 'preview-1',
      chatId: chatId,
      senderId: 'preview-them',
      text: 'Hey Jack, are we still on for the walk later?',
      createdAt: now.subtract(const Duration(minutes: 3)),
    ),
    ChatMessage(
      id: 'preview-2',
      chatId: chatId,
      senderId: 'preview-me',
      text: 'Definitely. I found a quieter route by the water.',
      createdAt: now.subtract(const Duration(minutes: 1)),
    ),
    ChatMessage(
      id: 'preview-3',
      chatId: chatId,
      senderId: 'preview-them',
      text: 'Perfect. I will bring the coffee.',
      createdAt: now,
    ),
  ];
}

/// Live messages for [chatId]. Preview mode (signed out / unconfigured)
/// emits [curatedChatMessages]; authenticated mode streams
/// `chats/{chatId}/messages` ordered by `createdAt` (see `ChatRepository`
/// and `firestore.rules` chat-member rule).
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  // Never crash the chat surface when Firebase is unreachable (tests,
  // desktop placeholders, offline). Any throw degrades to preview.
  try {
    final user = ref.watch(currentUserProvider);
    if (!FirebaseConfiguration.isAvailable || user == null) {
      return Stream.value(curatedChatMessages(chatId));
    }
    final repository = ref.watch(chatRepositoryProvider);
    return repository.streamMessages(chatId);
  } catch (_) {
    return Stream.value(curatedChatMessages(chatId));
  }
});
