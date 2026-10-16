import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:docmac_app/features/auth/data/auth_service.dart';
import 'package:docmac_app/features/auth/presentation/pages/auth_page.dart';
import 'package:docmac_app/features/auth/presentation/providers/auth_provider.dart';

class _FakeUser extends Fake implements User {
  _FakeUser({this.phone = '+2348012345678'});
  final String phone;
  @override
  String get uid => 'test-uid-123';
  @override
  String? get phoneNumber => phone;
  @override
  String? get displayName => null;
}

class _FakeAuthService extends Fake implements AuthService {
  _FakeAuthService({this.fakeUser});
  final User? fakeUser;

  @override
  User? get currentUser => fakeUser;

  bool sendPhoneVerificationCalled = false;
  String? lastSentPhone;
  bool verifyPhoneCodeCalled = false;
  bool completePhoneSignUpCalled = false;
  String? completedUsername;
  String? completedDisplayName;
  String? completedEmail;

  @override
  Future<void> sendPhoneVerification({
    required String phoneNumber,
    int? forceResendingToken,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException error) onFailure,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    sendPhoneVerificationCalled = true;
    lastSentPhone = phoneNumber;
    onCodeSent('test-verification-id', 12345);
  }

  @override
  Future<void> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    verifyPhoneCodeCalled = true;
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    return username != 'taken';
  }

  @override
  Future<void> completePhoneSignUp({
    required String username,
    String? displayName,
    String? contactEmail,
  }) async {
    completePhoneSignUpCalled = true;
    completedUsername = username;
    completedDisplayName = displayName;
    completedEmail = contactEmail;
  }
}

void main() {
  Widget buildApp({
    required AuthService authService,
    bool resume = false,
  }) {
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/register',
          builder: (context, state) => SignUpPage(resume: resume),
        ),
        GoRoute(
          path: '/orbit',
          builder: (context, state) =>
              const Scaffold(body: Text('OrbitScreen')),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('HomeScreen')),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) =>
              const Scaffold(body: Text('SignInScreen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(authService),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('SignUpPage workflow', () {
    testWidgets('fresh signup strictly starts at Step 0 with phone number entry',
        (tester) async {
      final fakeAuth = _FakeAuthService(fakeUser: null);
      await tester.pumpWidget(buildApp(authService: fakeAuth));
      await tester.pumpAndSettle();

      expect(find.text('Your phone number'), findsOneWidget);
      expect(
        find.text(
            'Choose your country and enter the number linked to your account.'),
        findsOneWidget,
      );
      expect(find.text('Send code'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);

      // Verify profile steps are not visible
      expect(find.text('Profile info'), findsNothing);
      expect(find.text('Choose a username'), findsNothing);
      expect(find.text('Add your email'), findsNothing);
    });

    testWidgets('Step 0 validates phone, sends OTP, and moves to Step 1',
        (tester) async {
      final fakeAuth = _FakeAuthService(fakeUser: null);
      await tester.pumpWidget(buildApp(authService: fakeAuth));
      await tester.pumpAndSettle();

      // Enter phone number
      final phoneInput = find.byType(TextFormField).first;
      await tester.enterText(phoneInput, '8012345678');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      expect(fakeAuth.sendPhoneVerificationCalled, isTrue);

      // Verify transition to Step 1
      expect(find.text('Confirm your number'), findsOneWidget);
      expect(find.text('Verify and continue'), findsOneWidget);
      expect(find.text('Didn’t receive a code? Send again'), findsOneWidget);

      // Verify back button takes user back to Step 0
      final backButton = find.byTooltip('Previous step');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Your phone number'), findsOneWidget);
      expect(find.byTooltip('Close signup'), findsOneWidget);
    });

    testWidgets('Step 1 verifies OTP and advances to profile setup',
        (tester) async {
      final fakeAuth = _FakeAuthService(fakeUser: null);
      await tester.pumpWidget(buildApp(authService: fakeAuth));
      await tester.pumpAndSettle();

      // Enter phone & send code
      final phoneInput = find.byType(TextFormField).first;
      await tester.enterText(phoneInput, '8012345678');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      // Enter 6-digit OTP code
      final otpInput = find.byType(TextFormField);
      await tester.enterText(otpInput, '123456');
      await tester.tap(find.text('Verify and continue'));
      await tester.pumpAndSettle();

      expect(fakeAuth.verifyPhoneCodeCalled, isTrue);

      // Should advance to Step 2 (Profile info)
      expect(find.text('Profile info'), findsOneWidget);
      expect(
          find.text('Please add the name people will know you by.'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('resume=true with existing phone session resumes at Step 2',
        (tester) async {
      final user = _FakeUser(phone: '+2348012345678');
      final fakeAuth = _FakeAuthService(fakeUser: user);
      await tester.pumpWidget(buildApp(authService: fakeAuth, resume: true));
      await tester.pumpAndSettle();

      // Directly on Step 2
      expect(find.text('Profile info'), findsOneWidget);
      expect(find.byKey(const Key('signup-full-name')), findsOneWidget);
    });

    testWidgets(
        'profile steps proceed through Full Name -> Username -> Email and complete with no fake email OTP',
        (tester) async {
      final user = _FakeUser(phone: '+2348012345678');
      final fakeAuth = _FakeAuthService(fakeUser: user);
      await tester.pumpWidget(buildApp(authService: fakeAuth, resume: true));
      await tester.pumpAndSettle();

      // Step 2: Full Name
      final nameField = find.byKey(const Key('signup-full-name'));
      await tester.enterText(nameField, 'Ada Lovelace');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 3: Username
      expect(find.text('Choose a username'), findsOneWidget);
      final usernameField = find.byKey(const Key('signup-username'));
      await tester.enterText(usernameField, 'adalove');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 4: Email
      expect(find.text('Add your email'), findsOneWidget);
      expect(find.text('This step is optional.'), findsOneWidget);
      expect(find.text('Complete setup'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Enter email and complete
      final emailField = find.byKey(const Key('signup-email'));
      await tester.enterText(emailField, 'ada@example.com');
      await tester.tap(find.text('Complete setup'));
      await tester.pumpAndSettle();

      // Confirms completePhoneSignUp was called directly without any fake email OTP step
      expect(fakeAuth.completePhoneSignUpCalled, isTrue);
      expect(fakeAuth.completedUsername, 'adalove');
      expect(fakeAuth.completedDisplayName, 'Ada Lovelace');
      expect(fakeAuth.completedEmail, 'ada@example.com');
    });

    testWidgets('skipping email step completes registration cleanly',
        (tester) async {
      final user = _FakeUser(phone: '+2348012345678');
      final fakeAuth = _FakeAuthService(fakeUser: user);
      await tester.pumpWidget(buildApp(authService: fakeAuth, resume: true));
      await tester.pumpAndSettle();

      // Step 2: Full Name
      await tester.enterText(
          find.byKey(const Key('signup-full-name')), 'Ada Lovelace');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 3: Username
      await tester.enterText(
          find.byKey(const Key('signup-username')), 'adalove');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 4: Skip
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(fakeAuth.completePhoneSignUpCalled, isTrue);
      expect(fakeAuth.completedUsername, 'adalove');
      expect(fakeAuth.completedDisplayName, 'Ada Lovelace');
      expect(fakeAuth.completedEmail, isNull);
    });
  });
}

