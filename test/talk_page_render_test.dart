import 'package:docmac_app/core/ui/docmac_iconly.dart';
import 'package:docmac_app/features/talk/data/talk_thread.dart';
import 'package:docmac_app/features/talk/presentation/pages/talk_page.dart';
import 'package:docmac_app/features/talk/presentation/providers/talk_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fakeThreads = curatedTalkThreads;

Future<void> pumpTalk(
  WidgetTester tester, {
  List<TalkThread>? threads,
  Stream<List<TalkThread>>? stream,
}) async {
  SharedPreferences.setMockInitialValues({});
  final inbox =
      stream ?? Stream<List<TalkThread>>.value(threads ?? _fakeThreads);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        talkThreadsProvider.overrideWith((ref) => inbox),
      ],
      child: const MaterialApp(home: Scaffold(body: TalkPage())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Talk page renders its header and inbox', (tester) async {
    await pumpTalk(tester);

    expect(find.text('Talk'), findsOneWidget);
    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Jack Wilson'), findsOneWidget);
    // Filters stay out of the way until the search field is activated.
    expect(find.byKey(const ValueKey('talk-search-filters')), findsNothing);
    expect(find.text('6'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('talk-search-input')));
    await tester.pumpAndSettle();

    // Unread pill is computed from the stream (2 + 4), not hardcoded.
    expect(find.byKey(const ValueKey('talk-search-filters')), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('All talks'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('talk-search-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('talk-search-filters')), findsNothing);
  });

  testWidgets('opening a talk lets the user send a message', (tester) async {
    await pumpTalk(tester);

    await tester.tap(find.text('Jack Wilson'));
    await tester.pumpAndSettle();

    expect(find.text('Active now'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'See you soon.');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('talk-send-message')));
    await tester.pumpAndSettle();

    expect(find.text('See you soon.'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to talks'));
    await tester.pumpAndSettle();
    expect(find.text('Talk'), findsOneWidget);
  });

  testWidgets('holding a talk exposes pin and archive actions', (tester) async {
    await pumpTalk(tester);

    await tester.longPress(find.text('Jack Wilson'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Pin talk'), findsOneWidget);
    expect(find.byTooltip('Selected talk actions'), findsOneWidget);

    await tester.tap(find.byTooltip('Pin talk'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Unpin talk'), findsOneWidget);

    // Pin persists to SharedPreferences keyed by stable thread id.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('docmac_talk_pinned'), contains('jack'));

    await tester.tap(find.byTooltip('Selected talk actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive chat'));
    await tester.pumpAndSettle();

    expect(find.text('Jack Wilson'), findsNothing);
    expect(prefs.getStringList('docmac_talk_archived'), contains('jack'));

    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();
    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('Jack Wilson'), findsOneWidget);

    await tester.tap(find.text('Jack Wilson'));
    await tester.pumpAndSettle();
    expect(find.text('Active now'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to talks'));
    await tester.pumpAndSettle();
    expect(find.text('Archived'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to Talk'));
    await tester.pumpAndSettle();
    expect(find.text('Talk'), findsOneWidget);
  });

  testWidgets('talk search filters and can be cleared', (tester) async {
    await pumpTalk(tester);

    await tester.enterText(find.byType(TextField).first, 'Emma');
    await tester.pumpAndSettle();
    expect(find.text('Emma Clarke'), findsOneWidget);
    expect(find.text('Jack Wilson'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Jack Wilson'), findsOneWidget);
  });

  testWidgets('mute persists without stub snackbars', (tester) async {
    await pumpTalk(tester);

    await tester.longPress(find.text('Emma Clarke'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mute notifications'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('docmac_talk_muted'), contains('emma'));
    expect(find.byIcon(DocmacIconlyLight.volumeUp), findsWidgets);
  });

  testWidgets('stream error shows retry without demo fallback', (tester) async {
    await pumpTalk(
      tester,
      stream: Stream<List<TalkThread>>.error(Exception('offline')),
    );

    expect(find.textContaining('Could not load talks'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    // A real signed-in inbox must not be replaced with demo conversations.
    expect(find.text('Jack Wilson'), findsNothing);
  });
}
