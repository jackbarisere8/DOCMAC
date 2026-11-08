import 'package:docmac_app/features/moments/presentation/pages/moment_archive_page.dart';
import 'package:docmac_app/features/moments/presentation/pages/moments_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(theme: ThemeData(useMaterial3: true), home: page),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('moment archive sorts, selects all and deletes', (tester) async {
    await _pump(tester, const MomentArchivePage());

    expect(find.text('Moment archive'), findsOneWidget);
    expect(find.text('Select all'), findsOneWidget);
    expect(find.text('4.2 MB'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('moment-archive-select-all')));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Delete selected'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete selected'));
    await tester.pumpAndSettle();

    expect(find.text('Your archive is empty'), findsOneWidget);
  });

  testWidgets('moments page opens the moment archive', (tester) async {
    await _pump(tester, const MomentsPage());

    await tester.tap(find.byKey(const ValueKey('moment-archive')));
    await tester.pumpAndSettle();

    expect(find.text('Moment archive'), findsOneWidget);
    expect(find.text('Select all'), findsOneWidget);
  });
}
