import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:docmac_app/features/auth/data/auth_service.dart';
import 'package:docmac_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:docmac_app/features/auth/presentation/providers/auth_provider.dart';

class _FakeResetAuthService extends Fake implements AuthService {
  _FakeResetAuthService();

  String token = List<String>.filled(64, 'a').join();

  String? requestedEmail;
  String? verifiedEmail;
  String? verifiedCode;
  String? completedToken;
  String? completedPassword;

  PasswordResetException? requestError;
  PasswordResetException? verifyError;
  PasswordResetException? completeError;

  String? devCode;

  @override
  Future<String?> requestPasswordResetCode({required String email}) async {
    requestedEmail = email;
    final error = requestError;
    if (error != null) throw error;
    return devCode;
  }

  @override
  Future<String> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    verifiedEmail = email;
    verifiedCode = code;
    final error = verifyError;
    if (error != null) throw error;
    return token;
  }

  @override
  Future<void> completePasswordReset({
    required String token,
    required String password,
  }) async {
    completedToken = token;
    completedPassword = password;
    final error = completeError;
    if (error != null) throw error;
  }
}

Widget _app(_FakeResetAuthService service) {
  final router = GoRouter(
    initialLocation: '/forgot-password',
    routes: [
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const Scaffold(
          body: Text('Auth landing'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [authServiceProvider.overrideWithValue(service)],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _reachCodeStep(
  WidgetTester tester,
  _FakeResetAuthService service, {
  String email = 'jack@example.com',
}) async {
  await tester.pumpWidget(_app(service));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('forgot-email')), email);
  await tester.tap(find.byKey(const Key('forgot-submit')));
  await tester.pumpAndSettle();
}

Future<void> _reachPasswordStep(
  WidgetTester tester,
  _FakeResetAuthService service,
) async {
  await _reachCodeStep(tester, service);
  await tester.enterText(find.byKey(const Key('forgot-code')), '123456');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('email step sends a code and shows the code step',
      (tester) async {
    final service = _FakeResetAuthService();

    await _reachCodeStep(tester, service, email: 'jack@example.com');

    expect(service.requestedEmail, 'jack@example.com');
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('jack@example.com'), findsOneWidget);
    expect(find.text('Verify code'), findsOneWidget);

    // Leave the resend countdown timer with a disposed tree.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an incorrect code shows the server error', (tester) async {
    final service = _FakeResetAuthService()
      ..verifyError = const PasswordResetException('invalid_code');

    await _reachCodeStep(tester, service);
    await tester.enterText(find.byKey(const Key('forgot-code')), '000000');
    await tester.pumpAndSettle();

    expect(service.verifiedCode, '000000');
    expect(find.textContaining('That code is incorrect'), findsOneWidget);
    expect(find.text('Create new password'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a valid code opens the password step', (tester) async {
    final service = _FakeResetAuthService();

    await _reachPasswordStep(tester, service);

    expect(service.verifiedEmail, 'jack@example.com');
    expect(service.verifiedCode, '123456');
    expect(find.text('Create new password'), findsOneWidget);
    expect(find.byKey(const Key('reset-password')), findsOneWidget);
    expect(find.byKey(const Key('reset-confirm')), findsOneWidget);
    expect(find.text('At least 8 characters'), findsOneWidget);
    expect(find.text('Passwords match'), findsOneWidget);
  });

  testWidgets('mismatched passwords keep the reset button disabled',
      (tester) async {
    final service = _FakeResetAuthService();
    await _reachPasswordStep(tester, service);

    await tester.enterText(
      find.byKey(const Key('reset-password')),
      'Sunshine-42',
    );
    await tester.enterText(
      find.byKey(const Key('reset-confirm')),
      'Sunshine-43',
    );
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('reset-submit')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('matching passwords complete the reset', (tester) async {
    final service = _FakeResetAuthService();
    await _reachPasswordStep(tester, service);

    await tester.enterText(
      find.byKey(const Key('reset-password')),
      'Sunshine-42',
    );
    await tester.enterText(
      find.byKey(const Key('reset-confirm')),
      'Sunshine-42',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('reset-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-submit')));
    await tester.pumpAndSettle();

    expect(service.completedToken, service.token);
    expect(service.completedPassword, 'Sunshine-42');
    expect(find.text('Password updated'), findsOneWidget);
    expect(find.text('Back to sign in'), findsOneWidget);
  });

  testWidgets('resend becomes available after the cooldown', (tester) async {
    final service = _FakeResetAuthService();

    await _reachCodeStep(tester, service);

    expect(find.textContaining('Resend in'), findsOneWidget);
    expect(find.text('Resend code'), findsNothing);

    await tester.pump(const Duration(seconds: 61));
    await tester.pump();

    expect(find.text('Resend code'), findsOneWidget);
  });

  testWidgets('emulator dev code is surfaced on the code step', (tester) async {
    final service = _FakeResetAuthService()..devCode = '654321';

    await _reachCodeStep(tester, service);

    expect(find.textContaining('Emulator code: 654321'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('start over returns to the email step', (tester) async {
    final service = _FakeResetAuthService();
    await _reachPasswordStep(tester, service);

    await tester.ensureVisible(find.text('Start over'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start over'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot password?'), findsOneWidget);
    expect(service.completedPassword, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
