import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_service.dart';
import '../../../../core/models/app_user.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider.autoDispose<User?>((ref) {
  if (Firebase.apps.isEmpty) {
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
