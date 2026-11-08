import 'dart:async';

import 'package:docmac_app/core/models/app_user.dart';
import 'package:docmac_app/core/ui/docmac_iconly.dart';
import 'package:docmac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:docmac_app/features/chat/data/models/chat_message.dart';
import 'package:docmac_app/features/chat/data/models/chat_thread.dart';
import 'package:docmac_app/features/chat/data/repositories/chat_repository.dart';
import 'package:docmac_app/features/chat/presentation/pages/chat_page.dart';
import 'package:docmac_app/features/chat/presentation/providers/chat_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _testUser =
    AppUser(id: 'my-uid', email: 'me@docmac.app', displayName: 'Me');

class MockChatRepository implements ChatRepository {
  MockChatRepository({List<ChatMessage>? seed})
      : messages = List.of(seed ?? <ChatMessage>[]);

  List<ChatMessage> messages;
  final markedRead = <String>[];
  final markedChatRead = <String>[];
  final _controllers = <String, StreamController<List<ChatMessage>>>{};

  List<ChatMessage> snapshot(String chatId) =>
      messages.where((m) => m.chatId == chatId).toList();

  @override
  Stream<List<ChatMessage>> streamMessages(String chatId) {
    final controller = StreamController<List<ChatMessage>>.broadcast();
    _controllers[chatId] = controller;
    scheduleMicrotask(() => controller.add(snapshot(chatId)));
    return controller.stream;
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required ChatMessage message,
  }) async {
    messages.add(message);
    _controllers[chatId]?.add(snapshot(chatId));
  }

  @override
  Future<void> markAsRead({
    required String chatId,
    required String messageId,
  }) async {
    markedRead.add(messageId);
  }

  @override
  Stream<List<ChatThread>> watchUserChats(String uid) {
    return Stream.value(curatedTalkThreads);
  }

  @override
  Future<DirectChat> ensureDirectChat({
    String? peerUid,
    String? peerHandle,
    String? peerName,
  }) async {
    return DirectChat(
      chatId: 'direct-test',
      peerUid: peerUid ?? 'peer-uid',
      peerName: peerName ?? 'Peer',
      peerHandle: peerHandle,
    );
  }

  @override
  Future<void> markChatRead(String chatId, String uid) async {
    markedChatRead.add(chatId);
  }

  void emit(String chatId, List<ChatMessage> newMessages) {
    messages = List.of(newMessages);
    _controllers[chatId]?.add(snapshot(chatId));
  }

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
  }
}

Future<void> pumpChat(
  WidgetTester tester, {
  required MockChatRepository repository,
  AppUser? user = _testUser,
  String chatId = 'jack',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
        currentUserProvider.overrideWithValue(user),
        chatMessagesProvider(chatId)
            .overrideWith((ref) => repository.streamMessages(chatId)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ChatPage(
            chatId: chatId,
            personName: 'Jack Wilson',
            status: 'Active now',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders header with peer name and active status',
      (tester) async {
    final repo = MockChatRepository();
    addTearDown(repo.dispose);

    await pumpChat(tester, repository: repo);

    expect(find.text('Jack Wilson'), findsOneWidget);
    expect(find.text('Active now'), findsOneWidget);
  });

  testWidgets('renders messages streamed from repository', (tester) async {
    final now = DateTime.now();
    final repo = MockChatRepository(seed: [
      ChatMessage(
        id: 'msg-1',
        chatId: 'jack',
        senderId: 'peer-uid',
        text: 'Hello from peer',
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      ChatMessage(
        id: 'msg-2',
        chatId: 'jack',
        senderId: 'my-uid',
        text: 'Hello back',
        createdAt: now.subtract(const Duration(minutes: 2)),
      ),
    ]);
    addTearDown(repo.dispose);

    await pumpChat(tester, repository: repo);

    expect(find.text('Hello from peer'), findsOneWidget);
    expect(find.text('Hello back'), findsOneWidget);
  });

  testWidgets('sending a message writes through ChatRepository.sendMessage',
      (tester) async {
    final repo = MockChatRepository();
    addTearDown(repo.dispose);

    await pumpChat(tester, repository: repo);

    await tester.enterText(find.byType(TextField), 'Testing message send');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('talk-send-message')));
    await tester.pumpAndSettle();

    expect(repo.messages.length, 1);
    expect(repo.messages.first.text, 'Testing message send');
    expect(repo.messages.first.senderId, 'my-uid');
    expect(repo.messages.first.chatId, 'jack');
    expect(find.text('Testing message send'), findsOneWidget);
  });

  testWidgets('selected message actions use the premium Docmac glyphs',
      (tester) async {
    final now = DateTime.now();
    final repo = MockChatRepository(seed: [
      ChatMessage(
        id: 'action-1',
        chatId: 'jack',
        senderId: 'peer-uid',
        text: 'Message with premium actions',
        createdAt: now,
      ),
    ]);
    addTearDown(repo.dispose);

    await pumpChat(tester, repository: repo);
    await tester.longPress(find.text('Message with premium actions'));
    await tester.pumpAndSettle();

    for (final tooltip in const [
      'Reply',
      'Delete',
      'Forward',
      'Archive talk',
      'Selected message actions',
    ]) {
      expect(find.byTooltip(tooltip), findsOneWidget);
    }
    expect(find.byIcon(DocmacIconlyLight.delete), findsOneWidget);
    expect(find.byIcon(Icons.forward_rounded), findsNothing);

    await tester.tap(find.byTooltip('Selected message actions'));
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Pin'), findsOneWidget);
    expect(find.text('Forward'), findsOneWidget);
  });

  testWidgets('marks incoming peer messages as read', (tester) async {
    final now = DateTime.now();
    final repo = MockChatRepository(seed: [
      ChatMessage(
        id: 'unread-1',
        chatId: 'jack',
        senderId: 'peer-uid',
        text: 'Unread peer message',
        createdAt: now,
        isRead: false,
      ),
    ]);
    addTearDown(repo.dispose);

    await pumpChat(tester, repository: repo);

    expect(repo.markedRead, contains('unread-1'));
  });
}
