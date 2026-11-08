import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/public_profile.dart';

/// Resolves public handles to UIDs and public profile data.
///
/// `usernames/{handle}` is the unique index; `publicProfiles/{uid}` holds the
/// name and photo that other signed-in people may see.
class UserDirectoryRepository {
  UserDirectoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  static String? normalizeHandle(String value) {
    final handle = value.trim().toLowerCase().replaceFirst(RegExp(r'^@'), '');
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(handle)) return null;
    return handle;
  }

  Future<PublicProfile?> findByHandle(String value) async {
    final handle = normalizeHandle(value);
    if (handle == null) return null;

    final usernameSnapshot =
        await _db.collection('usernames').doc(handle).get();
    final uid = usernameSnapshot.data()?['uid'];
    if (uid is! String || uid.isEmpty) return null;
    return getByUid(uid);
  }

  Future<PublicProfile?> getByUid(String uid) async {
    if (uid.isEmpty) return null;
    final snapshot = await _db.collection('publicProfiles').doc(uid).get();
    if (!snapshot.exists) return null;
    return PublicProfile.fromMap(uid, snapshot.data() ?? const {});
  }

  /// Exact-handle lookup used by the "New talk" screen. The public directory
  /// is intentionally read one document at a time; broad browsing arrives
  /// with the people-discovery phase.
  Future<PublicProfile?> findExact(String value) => findByHandle(value);
}
