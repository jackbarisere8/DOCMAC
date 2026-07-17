import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/app_user.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth}) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<AppUser?> signInWithEmailAndPassword({required String email, required String password}) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    final user = credential.user;
    if (user == null) {
      return null;
    }

    return AppUser(id: user.uid, email: user.email ?? email, displayName: user.displayName ?? user.email?.split('@').first);
  }

  Future<AppUser?> createUserWithEmailAndPassword({required String email, required String password}) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    final user = credential.user;
    if (user == null) {
      return null;
    }

    return AppUser(id: user.uid, email: user.email ?? email, displayName: user.displayName ?? user.email?.split('@').first);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
