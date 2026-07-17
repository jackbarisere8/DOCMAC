import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../shared/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isOnAuth = state.matchedLocation == '/auth';

      if (!isLoggedIn && !isOnAuth) {
        return '/auth';
      }
      if (isLoggedIn && isOnAuth) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const AppShell(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatPage(),
      ),
    ],
  );
});
