import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _textController = TextEditingController();
  final _chatId = 'demo-chat';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final repository = ref.read(chatRepositoryProvider);
    final message = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      chatId: _chatId,
      senderId: user.id,
      text: text,
      createdAt: DateTime.now(),
    );

    await repository.sendMessage(chatId: _chatId, message: message);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(chatRepositoryProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: repository.streamMessages(_chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == currentUser?.id;
                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMine ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(message.text),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
