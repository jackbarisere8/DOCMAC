import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

    test('AppUser accepts Firestore timestamps and legacy ISO dates', () {
      final timestamp = Timestamp.fromDate(DateTime.utc(2024, 1, 1));
      final fromTimestamp = AppUser.fromMap({
        'id': 'u1',
        'email': 'test@example.com',
        'createdAt': timestamp,
      });
      final fromIsoDate = AppUser.fromMap({
        'id': 'u2',
        'email': 'test@example.com',
        'createdAt': '2024-01-01T00:00:00.000Z',
      });

      expect(fromTimestamp.createdAt, timestamp.toDate());
      expect(fromIsoDate.createdAt, DateTime.utc(2024, 1, 1));
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
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('ChatMessage accepts Firestore timestamps and invalid legacy dates',
        () {
      final timestamp = Timestamp.fromDate(DateTime.utc(2024, 1, 1));
      final fromTimestamp = ChatMessage.fromMap({
        'id': 'm1',
        'chatId': 'chat-1',
        'senderId': 'u1',
        'text': 'Hello',
        'createdAt': timestamp,
      });
      final invalidDate = ChatMessage.fromMap({
        'id': 'm2',
        'chatId': 'chat-1',
        'senderId': 'u1',
        'text': 'Hello',
        'createdAt': 'not-a-date',
      });

      expect(fromTimestamp.createdAt, timestamp.toDate());
      expect(invalidDate.createdAt,
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
    });
  });
}
