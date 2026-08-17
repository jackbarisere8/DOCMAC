import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;

import 'config/router/app_router.dart';
import 'config/firebase/firebase_configuration.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

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
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeProvider = ThemeProvider();
  await Future.wait([
    initializeFirebase(),
    themeProvider.init(),
  ]);

  runApp(
    provider.ChangeNotifierProvider<ThemeProvider>.value(
      value: themeProvider,
      child: const ProviderScope(child: DocmacApp()),
    ),
  );
}

class DocmacApp extends ConsumerWidget {
  const DocmacApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = provider.Provider.of<ThemeProvider>(context).themeMode;

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
