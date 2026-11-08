import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/router/app_router.dart';
import 'config/firebase/firebase_configuration.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

/// Phone-auth test verification is deliberately opt-in.  A normal debug run
/// must retain Firebase's real app-verification flow, just like a release
/// build. Enable this only with:
/// `--dart-define=DOCMAC_USE_FIREBASE_TEST_PHONE_AUTH=true`
const _useFirebaseTestPhoneAuth = bool.fromEnvironment(
  'DOCMAC_USE_FIREBASE_TEST_PHONE_AUTH',
  defaultValue: false,
);

Future<void> initializeFirebase() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!FirebaseConfiguration.isConfigured) {
    debugPrint('Firebase is not configured; running in signed-out mode.');
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await _initializeObservability();

    // Firebase Console test numbers are the only phone numbers that work with
    // this setting. It is opt-in so a routine debug run cannot silently
    // disable Firebase's Play Integrity/reCAPTCHA protection.
    if (kDebugMode &&
        _useFirebaseTestPhoneAuth &&
        defaultTargetPlatform == TargetPlatform.android) {
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );
      debugPrint(
          'Phone Auth test verification is enabled for this debug build.');
    }
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

/// Connects crash reporting and product analytics without letting either
/// service take the app down. Debug builds stay out of Crashlytics so local
/// hot-reload errors never pollute production dashboards.
Future<void> _initializeObservability() async {
  if (kDebugMode) return;

  try {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
      return true;
    };
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  } catch (error) {
    debugPrint('Crashlytics could not start: $error');
  }

  try {
    final analytics = FirebaseAnalytics.instance;
    await analytics.setAnalyticsCollectionEnabled(true);
  } catch (error) {
    debugPrint('Analytics could not start: $error');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeFirebase();

  runApp(
    const ProviderScope(child: DocmacApp()),
  );
}

class DocmacApp extends ConsumerWidget {
  const DocmacApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Docmac',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
