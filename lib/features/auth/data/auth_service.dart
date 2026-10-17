import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../config/firebase/firebase_configuration.dart';
import '../../../core/models/app_user.dart';

class AuthServiceUnavailableException implements Exception {
  const AuthServiceUnavailableException(this.message);

  final String message;
}

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuthOverride = firebaseAuth;

  final FirebaseAuth? _firebaseAuthOverride;

  FirebaseAuth get _firebaseAuth {
    if (_firebaseAuthOverride != null) return _firebaseAuthOverride;

    if (!FirebaseConfiguration.isConfigured) {
      throw const AuthServiceUnavailableException(
        'Account services have not been configured for this app build.',
      );
    }

    if (!FirebaseConfiguration.isInitialized) {
      throw const AuthServiceUnavailableException(
        'Account services could not be started. Please try again later.',
      );
    }

    return FirebaseAuth.instance;
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<AppUser?> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    final user = credential.user;
    if (user == null) {
      return null;
    }

    return AppUser(
        id: user.uid,
        email: user.email ?? email,
        displayName: user.displayName ?? user.email?.split('@').first);
  }

  /// Starts Firebase's SMS verification flow. Phone numbers must be supplied
  /// in international E.164 form (for example, +2348012345678).
  Future<void> sendPhoneVerification({
    required String phoneNumber,
    int? forceResendingToken,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException error) onFailure,
    required Future<void> Function(PhoneAuthCredential credential)
        onAutoVerified,
  }) {
    return _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailure,
      codeSent: (verificationId, resendToken) =>
          onCodeSent(verificationId, resendToken),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> signInWithPhoneCredential(PhoneAuthCredential credential) {
    return _firebaseAuth.signInWithCredential(credential);
  }

  /// Confirms the code sent to the person's phone and restores their Firebase
  /// session. Firebase persists that session on native devices until sign-out.
  Future<void> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _firebaseAuth.signInWithCredential(credential);
  }

  /// Signs up a new account with email, password, username, and full name.
  /// This creates the Firebase Auth user and persists the claimed username
  /// and user profile document in Firestore in one verified transaction.
  Future<AppUser?> signUpWithEmailAndUsername({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    final normalizedUsername = _normalizeUsername(username);
    if (!_isValidUsername(normalizedUsername)) {
      throw const AuthServiceUnavailableException(
        'Use 3–20 lowercase letters, numbers, or underscores for your username.',
      );
    }

    final isAvailable = await isUsernameAvailable(normalizedUsername);
    if (!isAvailable) {
      throw const UsernameUnavailableException();
    }

    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      return null;
    }

    final name = displayName.trim();
    if (name.isNotEmpty) {
      await user.updateDisplayName(name);
      await user.reload();
    }

    final firestore = FirebaseFirestore.instance;
    await firestore.runTransaction((transaction) async {
      final usernameRef =
          firestore.collection('usernames').doc(normalizedUsername);
      final handleRef = firestore.collection('handles').doc(normalizedUsername);
      final usernameSnapshot = await transaction.get(usernameRef);
      final handleSnapshot = await transaction.get(handleRef);
      if (usernameSnapshot.exists &&
          usernameSnapshot.data()?['uid'] != user.uid) {
        throw const UsernameUnavailableException();
      }
      if (handleSnapshot.exists &&
          handleSnapshot.data()?['ownerId'] != user.uid) {
        throw const UsernameUnavailableException();
      }
      transaction.set(usernameRef, {'uid': user.uid});
      transaction.set(handleRef, {
        'kind': 'user',
        'ownerId': user.uid,
      });
      transaction.set(
        firestore.collection('users').doc(user.uid),
        {
          'username': normalizedUsername,
          'displayName': name.isNotEmpty ? name : normalizedUsername,
          'onboardingComplete': true,
          'contactEmail': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    final updatedUser = _firebaseAuth.currentUser ?? user;
    return AppUser(
      id: updatedUser.uid,
      email: updatedUser.email ?? email,
      displayName: updatedUser.displayName ?? name,
    );
  }

  /// Completes signup for a two-faced account: links the email & password
  /// credentials to the phone-verified session (or creates the user if no phone session),
  /// sets display name, and registers the username in Firestore.
  Future<AppUser?> completeDualSignUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    final normalizedUsername = _normalizeUsername(username);
    if (!_isValidUsername(normalizedUsername)) {
      throw const AuthServiceUnavailableException(
        'Use 3–20 lowercase letters, numbers, or underscores for your username.',
      );
    }

    final isAvailable = await isUsernameAvailable(normalizedUsername);
    if (!isAvailable) {
      throw const UsernameUnavailableException();
    }

    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        final emailCred = EmailAuthProvider.credential(
          email: email.trim(),
          password: password,
        );
        await user.linkWithCredential(emailCred);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'provider-already-linked') {
          try {
            await user.updatePassword(password);
          } catch (_) {}
        } else {
          rethrow;
        }
      }
    } else {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = credential.user;
      if (user == null) {
        return null;
      }
    }

    final User finalUser = user;

    final name = displayName.trim();
    if (name.isNotEmpty) {
      await finalUser.updateDisplayName(name);
      await finalUser.reload();
    }

    final firestore = FirebaseFirestore.instance;
    await firestore.runTransaction((transaction) async {
      final usernameRef =
          firestore.collection('usernames').doc(normalizedUsername);
      final handleRef = firestore.collection('handles').doc(normalizedUsername);
      final usernameSnapshot = await transaction.get(usernameRef);
      final handleSnapshot = await transaction.get(handleRef);
      if (usernameSnapshot.exists &&
          usernameSnapshot.data()?['uid'] != finalUser.uid) {
        throw const UsernameUnavailableException();
      }
      if (handleSnapshot.exists &&
          handleSnapshot.data()?['ownerId'] != finalUser.uid) {
        throw const UsernameUnavailableException();
      }
      transaction.set(usernameRef, {'uid': finalUser.uid});
      transaction.set(handleRef, {
        'kind': 'user',
        'ownerId': finalUser.uid,
      });
      transaction.set(
        firestore.collection('users').doc(finalUser.uid),
        {
          'username': normalizedUsername,
          'displayName': name.isNotEmpty ? name : normalizedUsername,
          'onboardingComplete': true,
          'contactEmail': email.trim(),
          'phoneNumber': finalUser.phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    final updatedUser = _firebaseAuth.currentUser ?? finalUser;
    return AppUser(
      id: updatedUser.uid,
      email: updatedUser.email ?? email,
      displayName: updatedUser.displayName ?? name,
    );
  }

  /// Completes a verified-phone account with Docmac's public profile. Phone
  /// OTP is the only authentication method; no hidden email/password account
  /// is created.
  Future<void> completePhoneSignUp({
    required String username,
    String? displayName,
    String? contactEmail,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.phoneNumber == null) {
      throw const AuthServiceUnavailableException(
        'Verify your phone number before completing your account.',
      );
    }

    final normalizedUsername = _normalizeUsername(username);
    if (!_isValidUsername(normalizedUsername)) {
      throw const AuthServiceUnavailableException(
        'Use 3–20 lowercase letters, numbers, or underscores for your username.',
      );
    }

    final name = displayName?.trim();
    final email = contactEmail?.trim();
    await user.updateDisplayName(
      name?.isNotEmpty == true ? name : normalizedUsername,
    );
    await user.reload();

    // Firestore gives usernames a stable, queryable home and prevents two
    // people from claiming the same public identity.
    final firestore = FirebaseFirestore.instance;
    await firestore.runTransaction((transaction) async {
      final usernameRef =
          firestore.collection('usernames').doc(normalizedUsername);
      final handleRef = firestore.collection('handles').doc(normalizedUsername);
      final usernameSnapshot = await transaction.get(usernameRef);
      final handleSnapshot = await transaction.get(handleRef);
      if (usernameSnapshot.exists &&
          usernameSnapshot.data()?['uid'] != user.uid) {
        throw const UsernameUnavailableException();
      }
      if (handleSnapshot.exists &&
          handleSnapshot.data()?['ownerId'] != user.uid) {
        throw const UsernameUnavailableException();
      }
      transaction.set(usernameRef, {'uid': user.uid});
      transaction.set(handleRef, {
        'kind': 'user',
        'ownerId': user.uid,
      });
      transaction.set(
          firestore.collection('users').doc(user.uid),
          {
            'username': normalizedUsername,
            'displayName': name?.isNotEmpty == true ? name : normalizedUsername,
            'onboardingComplete': true,
            'phoneNumber': user.phoneNumber,
            if (email?.isNotEmpty == true) 'contactEmail': email,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    });
  }

  /// Whether the signed-in user has finished profile onboarding.
  Future<bool> hasCompletedOnboarding() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));
      return snapshot.data()?['onboardingComplete'] == true;
    } catch (_) {
      return user.displayName != null && user.displayName!.isNotEmpty;
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    final normalizedUsername = _normalizeUsername(username);
    if (!_isValidUsername(normalizedUsername)) return false;
    final firestore = FirebaseFirestore.instance;
    final usernameSnapshot =
        await firestore.collection('usernames').doc(normalizedUsername).get();
    final handleSnapshot =
        await firestore.collection('handles').doc(normalizedUsername).get();
    final uid = _firebaseAuth.currentUser?.uid;
    final usernameAvailable =
        !usernameSnapshot.exists || usernameSnapshot.data()?['uid'] == uid;
    final handleAvailable =
        !handleSnapshot.exists || handleSnapshot.data()?['ownerId'] == uid;
    return usernameAvailable && handleAvailable;
  }

  Future<AppUser?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = credential.user;
    if (user == null) {
      return null;
    }

    final normalizedDisplayName = displayName?.trim();
    if (normalizedDisplayName != null && normalizedDisplayName.isNotEmpty) {
      await user.updateDisplayName(normalizedDisplayName);
      await user.reload();
    }

    final updatedUser = _firebaseAuth.currentUser ?? user;

    return AppUser(
      id: updatedUser.uid,
      email: updatedUser.email ?? email,
      displayName:
          updatedUser.displayName ?? updatedUser.email?.split('@').first,
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateDisplayName(String displayName) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceUnavailableException(
          'There is no signed-in account.');
    }
    await user.updateDisplayName(displayName);
    await user.reload();
  }

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceUnavailableException(
        'There is no signed-in account to verify.',
      );
    }
    await user.sendEmailVerification();
  }

  /// Reload the Firebase profile after a user opens the verification link.
  Future<bool> refreshEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthServiceUnavailableException(
        'There is no signed-in account to verify.',
      );
    }
    await user.reload();
    return _firebaseAuth.currentUser?.emailVerified ?? false;
  }

  Future<AppUser?> signInAnonymously() async {
    final credential = await _firebaseAuth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      return null;
    }

    return AppUser(
      id: user.uid,
      email: user.email ?? 'anonymous@docmac.app',
      displayName: user.displayName ?? 'Guest',
    );
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  static String _normalizeUsername(String username) =>
      username.trim().toLowerCase().replaceFirst(RegExp(r'^@'), '');

  static bool _isValidUsername(String username) =>
      RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username);
}

class UsernameUnavailableException implements Exception {
  const UsernameUnavailableException();
}
