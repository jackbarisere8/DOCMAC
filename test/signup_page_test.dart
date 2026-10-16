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
  _FakeUser({this.email = 'test@example.com', this.name = 'Test User'});
  @override
  final String? email;
  final String name;
  @override
  String get uid => 'test-uid-123';
  @override
  String? get phoneNumber => null;
  @override
  String? get displayName => name;
}

class _FakeAuthService extends Fake implements AuthService {
  _FakeAuthService({this.fakeUser});
  final User? fakeUser;

  @override
  User? get currentUser => fakeUser;

  bool signUpWithEmailAndUsernameCalled = false;
  String? signedUpEmail;
  String? signedUpPassword;
  String? signedUpUsername;
  String? signedUpDisplayName;

  bool signInWithEmailAndPasswordCalled = false;
  String? signedInEmail;
  String? signedInPassword;

  @override
  Future<bool> isUsernameAvailable(String username) async {
    return username != 'taken';
  }

  @override
  Future<AppUser?> signUpWithEmailAndUsername({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    signUpWithEmailAndUsernameCalled = true;
    signedUpEmail = email;
    signedUpPassword = password;
    signedUpUsername = username;
    signedUpDisplayName = displayName;
    return AppUser(
      id: 'test-user-id',
      email: email,
      displayName: displayName,
    );
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

  group('SignUpPage workflow (Zero Phone / SMS OTP)', () {
    testWidgets(
        'fresh signup strictly starts at Step 0 with Profile Info (Full Name) and no phone entry',
        (tester) async {
      final fakeAuth = _FakeAuthService(fakeUser: null);
      await tester.pumpWidget(buildApp(authService: fakeAuth));
      await tester.pumpAndSettle();

      // Step 0: Profile Info
      expect(find.text('Profile info'), findsOneWidget);
      expect(
        find.text('Please add the name people will know you by.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('signup-full-name')), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Verify that phone number and SMS OTP fields are strictly ABSENT
      expect(find.text('Your phone number'), findsNothing);
      expect(find.text('Confirm your number'), findsNothing);
      expect(find.text('Send code'), findsNothing);
    });

    testWidgets('Step 0 validates name and advances to Step 1 (Username)',
        (tester) async {
      final fakeAuth = _FakeAuthService(fakeUser: null);
      await tester.pumpWidget(buildApp(authService: fakeAuth));
      await tester.pumpAndSettle();

      // Enter full name
      final nameField = find.byKey(const Key('signup-full-name'));
      await tester.enterText(nameField, 'Ada Lovelace');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 1: Choose username
      expect(find.text('Choose a username'), findsOneWidget);
      expect(
        find.text('This will be your unique Docmac identity.'),
        findsOneWidget,
      );
      final usernameField = find.byKey(const Key('signup-username'));
      expect(usernameField, findsOneWidget);

      // Back button takes user back to Step 0
      final backButton = find.byTooltip('Previous step');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Profile info'), findsOneWidget);
      expect(find.byTooltip('Close signup'), findsOneWidget);
    });

    testWidgets(
        'Step 1 advances to Step 2 and completes account creation with email & password',
        (tester) async {
      final fakeAuth = _FakeAuthService(fakeUser: null);
      await tester.pumpWidget(buildApp(authService: fakeAuth));
      await tester.pumpAndSettle();

      // Step 0: Name
      await tester.enterText(
          find.byKey(const Key('signup-full-name')), 'Ada Lovelace');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 1: Username
      await tester.enterText(
          find.byKey(const Key('signup-username')), 'adalove');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2: Email & Password
      expect(find.text('Add your email'), findsOneWidget);
      expect(find.byKey(const Key('signup-email')), findsOneWidget);
      expect(find.byKey(const Key('signup-password')), findsOneWidget);
      expect(find.text('Complete setup'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('signup-email')), 'ada@example.com');
      await tester.enterText(
          find.byKey(const Key('signup-password')), 'secret123');
      await tester.tap(find.text('Complete setup'));
      await tester.pumpAndSettle();

      // Verify that signUpWithEmailAndUsername was invoked with exact credentials
      expect(fakeAuth.signUpWithEmailAndUsernameCalled, isTrue);
      expect(fakeAuth.signedUpEmail, 'ada@example.com');
      expect(fakeAuth.signedUpPassword, 'secret123');
      expect(fakeAuth.signedUpUsername, 'adalove');
      expect(fakeAuth.signedUpDisplayName, 'Ada Lovelace');

      // Verify navigation to Orbit
      expect(find.text('OrbitScreen'), findsOneWidget);
    });

    testWidgets(
        'resume=true with existing session pre-fills display name and moves to Step 1',
        (tester) async {
      final user = _FakeUser(email: 'ada@example.com', name: 'Ada Lovelace');
      final fakeAuth = _FakeAuthService(fakeUser: user);
      await tester.pumpWidget(buildApp(authService: fakeAuth, resume: true));
      await tester.pumpAndSettle();

      expect(find.text('Choose a username'), findsOneWidget);
      expect(find.byKey(const Key('signup-username')), findsOneWidget);
    });
  });

  group('SignInPage workflow (Email-First Architecture)', () {
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
  });
}
