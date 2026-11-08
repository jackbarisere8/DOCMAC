import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/feature_flags.dart';
import '../../../../config/firebase/firebase_configuration.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';

final chatRepositoryProvider =
    Provider<ChatRepository>((ref) => ChatRepository());

/// Preview conversation shown only when signed out or when Firebase is not
/// configured. Authenticated users always see their real Firestore messages;
/// demo text must never appear in a production conversation.
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

/// Live messages for [chatId].
///
/// Preview mode (signed out / unconfigured) emits [curatedChatMessages].
/// Authenticated mode streams `chats/{chatId}/messages` and surfaces errors
/// to the chat surface instead of replacing them with fake history.
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final user = ref.watch(currentUserProvider);
  if (!FirebaseConfiguration.isAvailable || user == null || chatId.isEmpty) {
    final canPreview = user == null && AppFeatureFlags.signedOutPreviews;
    return Stream.value(
      canPreview ? curatedChatMessages(chatId) : const <ChatMessage>[],
    );
  }
  return ref.watch(chatRepositoryProvider).streamMessages(chatId);
});
