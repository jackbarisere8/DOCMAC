import 'package:docmac_app/core/ui/docmac_community_icons.dart';
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

  testWidgets('pinning a talk moves it to the top of the inbox',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TalkPage())),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Weekend crew'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Pin talk'));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DocmacCommunityIcon &&
            widget.semanticLabel == 'Pinned talk',
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('Weekend crew')).dy,
      lessThan(tester.getTopLeft(find.text('Jack Wilson')).dy),
    );
  });
}
