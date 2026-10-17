import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:docmac_app/core/models/app_user.dart';
import 'package:docmac_app/features/auth/data/auth_service.dart';
import 'package:docmac_app/features/auth/presentation/pages/auth_page.dart';
import 'package:docmac_app/features/auth/presentation/providers/auth_provider.dart';

class _FakeUser extends Fake implements User {
  _FakeUser({
    this.email = 'test@example.com',
    this.name = 'Test User',
    this.phone = '+18012345678',
  });
  @override
  final String? email;
  final String name;
  final String? phone;
  @override
  String get uid => 'test-uid-123';
  @override
  String? get phoneNumber => phone;
  @override
  String? get displayName => name;
}

class _FakeAuthService extends Fake implements AuthService {
  _FakeAuthService({this.fakeUser});
  final User? fakeUser;

  @override
  User? get currentUser => fakeUser;

  bool sendPhoneVerificationCalled = false;
  String? phoneVerificationSentNumber;

  bool verifyPhoneCodeCalled = false;
  String? verifiedVerificationId;
  String? verifiedSmsCode;

  bool completeDualSignUpCalled = false;
  String? completedEmail;
  String? completedPassword;
  String? completedUsername;
  String? completedDisplayName;

  bool completePhoneSignUpCalled = false;
  String? phoneSignUpUsername;
  String? phoneSignUpDisplayName;
  String? phoneSignUpContactEmail;

  bool signInWithEmailAndPasswordCalled = false;
  String? signedInEmail;
  String? signedInPassword;

  @override
  Future<void> sendPhoneVerification({
    required String phoneNumber,
    int? forceResendingToken,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException error) onFailure,
    required Future<void> Function(PhoneAuthCredential credential)
        onAutoVerified,
  }) async {
    sendPhoneVerificationCalled = true;
    phoneVerificationSentNumber = phoneNumber;
    onCodeSent('fake-verification-id', 12345);
  }

  @override
  Future<void> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    verifyPhoneCodeCalled = true;
    verifiedVerificationId = verificationId;
    verifiedSmsCode = smsCode;
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    return username != 'taken';
  }

  @override
  Future<AppUser?> completeDualSignUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    completeDualSignUpCalled = true;
    completedEmail = email;
    completedPassword = password;
    completedUsername = username;
    completedDisplayName = displayName;
    return AppUser(
      id: 'test-user-id',
      email: email,
      displayName: displayName,
    );
  }

  @override
  Future<void> completePhoneSignUp({
    required String username,
    String? displayName,
    String? contactEmail,
  }) async {
    completePhoneSignUpCalled = true;
    phoneSignUpUsername = username;
    phoneSignUpDisplayName = displayName;
    phoneSignUpContactEmail = contactEmail;
  }

  @override
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInWithEmailAndPasswordCalled = true;
    signedInEmail = email;
    signedInPassword = password;
    return AppUser(
      id: 'test-user-id',
      email: email,
      displayName: 'Signed In User',
    );
  }

  @override
  Future<bool> hasCompletedOnboarding() async => true;
}

void main() {
  Widget buildApp({
    required AuthService authService,
    String initialLocation = '/register',
    bool resume = false,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
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
          builder: (context, state) => const SignInPage(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) =>
              const Scaffold(body: Text('ForgotPasswordScreen')),
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

  group('SignUpPage workflow (Phone OTP -> Full Name, Username, Email)', () {
    testWidgets('fresh signup starts at Step 0 with Phone Number entry',
        (tester) async {
      final fakeAuth = _FakeAuthService(fakeUser: null);
      await tester.pumpWidget(buildApp(authService: fakeAuth));
      await tester.pumpAndSettle();

      // Step 0: Phone number
      expect(find.text('Your phone number'), findsOneWidget);
      expect(
        find.text(
          'Choose your country and enter your mobile number for OTP verification.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('signup-phone')), findsOneWidget);
      expect(find.text('Send code'), findsOneWidget);
    });

    testWidgets(
        'Step 0 confirms phone dialog and sends OTP, advancing to Step 1',
        (tester) async {
      final fakeAuth = _FakeAuthService(fakeUser: null);
      await tester.pumpWidget(buildApp(authService: fakeAuth));
      await tester.pumpAndSettle();

      // Enter phone number
      final phoneField = find.byKey(const Key('signup-phone'));
      await tester.enterText(phoneField, '8012345678');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      // Dialog confirmation
      expect(find.text('Confirm your number'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should have triggered sendPhoneVerification
      expect(fakeAuth.sendPhoneVerificationCalled, isTrue);

      // Now at Step 1: OTP verification
      expect(find.byKey(const Key('signup-otp')), findsOneWidget);
      expect(find.text('Verify and continue'), findsOneWidget);
    });

    testWidgets(
        'Step 1 verifies OTP and advances to next page with full name, username, and email',
        (tester) async {
      final fakeAuth = _FakeAuthService(fakeUser: null);
      await tester.pumpWidget(buildApp(authService: fakeAuth));
      await tester.pumpAndSettle();

      // Send OTP
      await tester.enterText(
          find.byKey(const Key('signup-phone')), '8012345678');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Enter OTP
      await tester.enterText(find.byKey(const Key('signup-otp')), '123456');
      await tester.tap(find.text('Verify and continue'));
      await tester.pumpAndSettle();

      // Verified code
      expect(fakeAuth.verifyPhoneCodeCalled, isTrue);
      expect(fakeAuth.verifiedVerificationId, 'fake-verification-id');
      expect(fakeAuth.verifiedSmsCode, '123456');

      // Now at Next Page: Profile info containing full name, username, and email
      expect(find.text('Profile info'), findsOneWidget);
      expect(find.byKey(const Key('signup-full-name')), findsOneWidget);
      expect(find.byKey(const Key('signup-username')), findsOneWidget);
      expect(find.byKey(const Key('signup-email')), findsOneWidget);
      expect(find.byKey(const Key('signup-password')), findsOneWidget);
      expect(find.text('Complete setup'), findsOneWidget);
    });

    testWidgets(
        'Full flow completes account on the profile page and routes to /orbit',
        (tester) async {
      final fakeAuth = _FakeAuthService(fakeUser: null);
      await tester.pumpWidget(buildApp(authService: fakeAuth));
      await tester.pumpAndSettle();

      // Step 0: Phone
      await tester.enterText(
          find.byKey(const Key('signup-phone')), '8012345678');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 1: OTP
      await tester.enterText(find.byKey(const Key('signup-otp')), '123456');
      await tester.tap(find.text('Verify and continue'));
      await tester.pumpAndSettle();

      // Step 2: Full Name, Username, Email on next page
      expect(find.text('Profile info'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('signup-full-name')), 'Ada Lovelace');
      await tester.enterText(
          find.byKey(const Key('signup-username')), 'adalove');
      await tester.enterText(
          find.byKey(const Key('signup-email')), 'ada@example.com');
      await tester.enterText(
          find.byKey(const Key('signup-password')), 'secret123');
      await tester.ensureVisible(find.text('Complete setup'));
      await tester.tap(find.text('Complete setup'));
      await tester.pumpAndSettle();

      // Verify that completeDualSignUp was invoked with exact credentials
      expect(fakeAuth.completeDualSignUpCalled, isTrue);
      expect(fakeAuth.completedEmail, 'ada@example.com');
      expect(fakeAuth.completedPassword, 'secret123');
      expect(fakeAuth.completedUsername, 'adalove');
      expect(fakeAuth.completedDisplayName, 'Ada Lovelace');

      // Verify navigation to Orbit
      expect(find.text('OrbitScreen'), findsOneWidget);
    });

    testWidgets(
        'resume=true with existing phone session moves directly to Profile Info page',
        (tester) async {
      final user = _FakeUser(
        email: 'ada@example.com',
        name: 'Ada Lovelace',
        phone: '+2348012345678',
      );
      final fakeAuth = _FakeAuthService(fakeUser: user);
      await tester.pumpWidget(buildApp(authService: fakeAuth, resume: true));
      await tester.pumpAndSettle();

      expect(find.text('Profile info'), findsOneWidget);
      expect(find.byKey(const Key('signup-full-name')), findsOneWidget);
      expect(find.byKey(const Key('signup-username')), findsOneWidget);
      expect(find.byKey(const Key('signup-email')), findsOneWidget);
    });
  });

  group('SignInPage workflow (Email-First Architecture with Phone Option)', () {
    testWidgets('renders email sign-in inputs and submits successfully',
        (tester) async {
      final fakeAuth = _FakeAuthService(fakeUser: null);
      await tester.pumpWidget(
        buildApp(authService: fakeAuth, initialLocation: '/auth'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byKey(const Key('signin-email')), findsOneWidget);
      expect(find.byKey(const Key('signin-password')), findsOneWidget);
      expect(find.byKey(const Key('signin-submit')), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('signin-email')), 'jack@example.com');
      await tester.enterText(
          find.byKey(const Key('signin-password')), 'pass1234');
      await tester.tap(find.byKey(const Key('signin-submit')));
      await tester.pumpAndSettle();

      expect(fakeAuth.signInWithEmailAndPasswordCalled, isTrue);
      expect(fakeAuth.signedInEmail, 'jack@example.com');
      expect(fakeAuth.signedInPassword, 'pass1234');
      expect(find.text('OrbitScreen'), findsOneWidget);
    });

    testWidgets('navigates to forgot password and signup from signin',
        (tester) async {
      final fakeAuth = _FakeAuthService(fakeUser: null);
      await tester.pumpWidget(
        buildApp(authService: fakeAuth, initialLocation: '/auth'),
      );
      await tester.pumpAndSettle();

      // Tap Forgot password
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('ForgotPasswordScreen'), findsOneWidget);
    });

    testWidgets('can toggle between email and phone sign-in mode',
        (tester) async {
      final fakeAuth = _FakeAuthService(fakeUser: null);
      await tester.pumpWidget(
        buildApp(authService: fakeAuth, initialLocation: '/auth'),
      );
      await tester.pumpAndSettle();

      // Switch to phone
      await tester.tap(find.text('Sign in with phone number'));
      await tester.pumpAndSettle();

      expect(find.text('Your phone number'), findsOneWidget);
      expect(
        find.text(
          'Confirm your country code and enter the phone number\nlinked to your Docmac account.',
        ),
        findsOneWidget,
      );

      // Back to email sign in
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byKey(const Key('signin-email')), findsOneWidget);
    });
  });
}
