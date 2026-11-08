import 'package:docmac_app/features/moments/presentation/pages/moments_page.dart';
import 'package:docmac_app/features/people/presentation/pages/people_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpPage(
  WidgetTester tester,
  Widget page, {
  bool dark = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dark
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true),
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Your People surfaces requests and the add-people flow',
      (tester) async {
    await _pumpPage(tester, const YourPeoplePage());

    expect(find.text('Link requests'), findsOneWidget);
    expect(find.text('Accept'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('your-people-add')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('your-people-add')));
    await tester.pumpAndSettle();

    expect(find.text('PEOPLE YOU MAY KNOW'), findsOneWidget);
    expect(find.text('Maya Chen'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('add-person-mayac')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Link requests are not available yet. Nothing was sent to Maya.',
      ),
      findsOneWidget,
    );
    expect(find.text('Requested'), findsNothing);
  });

  testWidgets('Moment viewer exposes views, menu actions and caption edit',
      (tester) async {
    await _pumpPage(tester, const MomentsPage());

    expect(find.text('Your moments'), findsOneWidget);
    expect(find.text('8 views'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('moment-views-mine-1')));
    await tester.pumpAndSettle();
    expect(find.text('Seen by 8'), findsOneWidget);
    expect(find.text('Amara Okafor'), findsOneWidget);

    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();

    await tester.tap(find.text('A quiet morning, a full heart.'));
    await tester.pumpAndSettle();

    expect(find.text('My moment'), findsOneWidget);
    expect(find.text('Seen by 8'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('moment-viewer-menu')));
    await tester.pumpAndSettle();

    expect(find.text('Edit caption'), findsOneWidget);
    expect(find.text('Forward'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Delete moment'), findsOneWidget);

    await tester.tap(find.text('Edit caption'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'A softer morning, a full heart.',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('A softer morning, a full heart.'), findsOneWidget);
  });

  testWidgets('Moment card menu can delete a moment', (tester) async {
    await _pumpPage(tester, const MomentsPage());

    await tester.tap(find.byKey(const ValueKey('moment-card-menu-mine-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete moment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('A quiet morning, a full heart.'), findsNothing);
    expect(find.text('8 views'), findsNothing);
    expect(find.text('Moment deleted.'), findsOneWidget);
  });

  testWidgets('New moment sheet previews and shares a caption', (tester) async {
    await _pumpPage(tester, const MomentsPage());

    await tester.tap(find.byKey(const ValueKey('new-moment')));
    await tester.pumpAndSettle();

    expect(find.text('New moment'), findsOneWidget);
    expect(find.text('Share moment'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'A fresh page');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Share moment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share moment'));
    await tester.pumpAndSettle();

    expect(find.text('A fresh page'), findsOneWidget);
    expect(find.text('No views yet'), findsOneWidget);
  });
}
