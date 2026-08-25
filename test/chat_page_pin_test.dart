import 'package:docmac_app/features/chat/presentation/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pinning a message keeps it at the top of the chat',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatPage()));
    await tester.pumpAndSettle();

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
}
