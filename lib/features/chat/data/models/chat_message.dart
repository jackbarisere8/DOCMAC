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
      createdAt: DateTime.parse(map['createdAt'].toString()),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }
}
