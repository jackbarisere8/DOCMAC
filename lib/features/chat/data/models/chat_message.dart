import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      chatId: map['chatId'] as String,
      senderId: map['senderId'] as String,
      text: map['text'] as String,
      createdAt: _readCreatedAt(map['createdAt']),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  static DateTime _readCreatedAt(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      // Firestore rules require a timestamp, not an ISO-8601 string.
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}
