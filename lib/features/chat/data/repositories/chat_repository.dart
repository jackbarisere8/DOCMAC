import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ChatMessage.fromMap({...doc.data(), 'id': doc.id})).toList());
  }

  Future<void> sendMessage({required String chatId, required ChatMessage message}) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }
}
