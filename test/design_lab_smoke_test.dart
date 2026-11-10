import 'package:docmac_app/config/feature_flags.dart';
import 'package:docmac_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'design lab boots into the app shell without Firebase',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ProviderScope(child: DocmacApp()));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(Banner), findsOneWidget);
      expect(find.text('Talk'), findsWidgets);
      expect(find.text('Orbit'), findsWidgets);

      await tester.tap(find.text('Talk').last);
      await tester.pumpAndSettle();
      expect(find.text('Jack Wilson'), findsOneWidget);

      await tester.tap(find.text('Jack Wilson'));
      await tester.pumpAndSettle();
      expect(find.text('Preview — sign in to sync talks.'), findsOneWidget);
      expect(
        find.textContaining('I found a quieter route by the water.'),
        findsOneWidget,
      );
    },
    skip: !AppFeatureFlags.designLab,
  );
}
