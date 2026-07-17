import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_service.dart';
import '../../../core/models/app_user.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider.autoDispose((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges;
});

final currentUserProvider = Provider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return null;
  }
  return AppUser(id: user.uid, email: user.email ?? 'anonymous@docmac.app', displayName: user.displayName ?? 'Guest');
});
