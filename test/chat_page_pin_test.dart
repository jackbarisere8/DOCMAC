import 'dart:async';

import 'package:docmac_app/core/models/app_user.dart';
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
    AppUser(id: 'test-uid', email: 'test@docmac.app', displayName: 'Test');

List<ChatMessage> _seed(String chatId) {
  final now = DateTime.now();
  return [
    ChatMessage(
      id: 'm1',
      chatId: chatId,
      senderId: 'peer-uid',
      text: 'Hey Jack, are we still on for the walk later?',
      createdAt: now.subtract(const Duration(minutes: 3)),
    ),
    ChatMessage(
      id: 'm2',
      chatId: chatId,
      senderId: 'test-uid',
      text: 'Definitely. I found a quieter route by the water.',
      createdAt: now.subtract(const Duration(minutes: 1)),
    ),
    ChatMessage(
      id: 'm3',
      chatId: chatId,
      senderId: 'peer-uid',
      text: 'Perfect. I will bring the coffee.',
      createdAt: now,
    ),
  ];
}

/// In-memory [ChatRepository] so tests exercise the real provider wiring
/// (stream → send → read receipt) without Firestore.
class FakeChatRepository implements ChatRepository {
  FakeChatRepository({List<ChatMessage>? seed})
      : messages = List.of(seed ?? <ChatMessage>[]);

  List<ChatMessage> messages;
  final markedRead = <String>[];
  bool failSend = false;
  final _controllers = <String, StreamController<List<ChatMessage>>>{};

  List<ChatMessage> snapshot(String chatId) =>
      messages.where((m) => m.chatId == chatId).toList();

  @override
  Stream<List<ChatMessage>> streamMessages(String chatId) {
    final controller = StreamController<List<ChatMessage>>();
    controller.add(snapshot(chatId));
    _controllers[chatId] = controller;
    return controller.stream;
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required ChatMessage message,
  }) async {
    if (failSend) throw Exception('send failed');
    messages = [...messages, message];
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
  Stream<List<ChatThread>> watchUserChats(String uid) =>
      Stream.value(curatedTalkThreads);

  @override
  Future<String> createOrGetDirectChat({
    required String currentUid,
    required String peerUid,
    required String peerName,
  }) async =>
      'chat-1';

  @override
  Future<void> markChatRead(String chatId, String uid) async {}

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
  }
}

Future<void> pumpPreviewChat(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: ChatPage()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<FakeChatRepository> pumpLiveChat(
  WidgetTester tester, {
  String chatId = 'test-chat',
  List<ChatMessage>? seed,
}) async {
  final fake = FakeChatRepository(seed: seed ?? _seed(chatId));
  addTearDown(fake.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(_testUser),
        chatRepositoryProvider.overrideWithValue(fake),
        chatMessagesProvider
            .overrideWith((ref, id) => fake.streamMessages(id)),
      ],
      child: MaterialApp(home: ChatPage(chatId: chatId)),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets('pinning a message keeps it at the top of the chat',
      (tester) async {
    await pumpPreviewChat(tester);

    await tester.longPress(find.text('Perfect. I will bring the coffee.'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Selected message actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pin'));
    await tester.pumpAndSettle();

    expect(find.text('Pinned message'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Pinned message')).dy,
      lessThan(tester.getTopLeft(find.text('TODAY')).dy),
    );
  });

  testWidgets('preview send appends locally with sign-in banner',
      (tester) async {
    await pumpPreviewChat(tester);

    expect(find.text('Preview — sign in to sync talks.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'See you soon.');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('talk-send-message')));
    await tester.pumpAndSettle();

    expect(find.text('See you soon.'), findsOneWidget);
  });

  testWidgets('authenticated send writes through the repository',
      (tester) async {
    final fake = await pumpLiveChat(tester);

    // No preview banner once signed in.
    expect(find.text('Preview — sign in to sync talks.'), findsNothing);
    expect(find.text('Perfect. I will bring the coffee.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'On my way.');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('talk-send-message')));
    await tester.pumpAndSettle();

    expect(find.text('On my way.'), findsOneWidget);
    expect(
      fake.messages.any((m) =>
          m.text == 'On my way.' &&
          m.senderId == 'test-uid' &&
          m.chatId == 'test-chat'),
      isTrue,
    );
  });

  testWidgets('peer messages are marked read on view', (tester) async {
    final fake = await pumpLiveChat(tester);

    expect(fake.markedRead, containsAll(['m1', 'm3']));
  });

  testWidgets('failed send keeps the draft and offers retry', (tester) async {
    final fake = await pumpLiveChat(tester);
    fake.failSend = true;

    await tester.enterText(find.byType(TextField), 'Hello?');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('talk-send-message')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not send'), findsOneWidget);
    // Draft is preserved for retry.
    expect(find.text('Hello?'), findsOneWidget);
    expect(fake.messages.any((m) => m.text == 'Hello?'), isFalse);
  });

  testWidgets('stream error shows retry with preview fallback',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(_testUser),
          chatMessagesProvider.overrideWith(
            (ref, _) => Stream<List<ChatMessage>>.error(Exception('offline')),
          ),
        ],
        child: const MaterialApp(home: ChatPage(chatId: 'missing-chat')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not load messages'), findsOneWidget);
    // Curated fallback keeps the surface useful.
    expect(find.text('Perfect. I will bring the coffee.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
