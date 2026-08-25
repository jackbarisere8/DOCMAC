import 'package:docmac_app/features/talk/presentation/pages/talk_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Talk page renders its header and inbox', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TalkPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Talk'), findsOneWidget);
    expect(find.text('Inbox'), findsOneWidget);
  });

  testWidgets('opening a talk lets the user send a message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TalkPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jack Wilson'));
    await tester.pumpAndSettle();

    expect(find.text('Active now'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'See you soon.');
    await tester.tap(find.byType(InkWell).last);
    await tester.pumpAndSettle();

    expect(find.text('See you soon.'), findsOneWidget);
  });
}
