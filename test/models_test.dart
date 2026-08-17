import 'package:flutter_test/flutter_test.dart';
import 'package:docmac_app/core/models/app_user.dart';
import 'package:docmac_app/features/chat/data/models/chat_message.dart';

void main() {
  group('app models', () {
    test('AppUser serializes and deserializes correctly', () {
      const user =
          AppUser(id: 'u1', email: 'test@example.com', displayName: 'Tester');

      final map = user.toMap();
      final restored = AppUser.fromMap(map);

      expect(restored.id, 'u1');
      expect(restored.email, 'test@example.com');
      expect(restored.displayName, 'Tester');
    });

    test('ChatMessage serializes and deserializes correctly', () {
      final message = ChatMessage(
        id: 'm1',
        chatId: 'chat-1',
        senderId: 'u1',
        text: 'Hello',
        createdAt: DateTime.utc(2024, 1, 1),
      );

      final map = message.toMap();
      final restored = ChatMessage.fromMap(map);

      expect(restored.text, 'Hello');
      expect(restored.chatId, 'chat-1');
      expect(restored.senderId, 'u1');
    });
  });
}
