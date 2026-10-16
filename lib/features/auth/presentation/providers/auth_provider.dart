import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_service.dart';
import '../../../../core/models/app_user.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider.autoDispose<User?>((ref) {
  // `Firebase.apps` throws when Firebase was never initialized (notably in
  // widget tests). Degrade to signed-out instead of crashing providers.
  try {
    if (Firebase.apps.isEmpty) {
      return Stream<User?>.value(null);
    }
  } catch (_) {
    return Stream<User?>.value(null);
  }

  final service = ref.watch(authServiceProvider);
  return service.authStateChanges.handleError((_, __) => null);
});

final currentUserProvider = Provider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return null;
  }
  return AppUser(
      id: user.uid,
      email: user.email ?? 'anonymous@docmac.app',
      displayName: user.displayName ?? 'Guest',
      photoUrl: user.photoURL);
});
