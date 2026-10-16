import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docmac_app/main.dart';

void main() {
  testWidgets('app shows the welcome screen after the splash screen',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DocmacApp()),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Docmac'), findsOneWidget);
    expect(find.text('The people that matter.\nAlways within reach.'),
        findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  test('firebase initialization completes without crashing', () async {
    await expectLater(initializeFirebase(), completes);
  });
}
