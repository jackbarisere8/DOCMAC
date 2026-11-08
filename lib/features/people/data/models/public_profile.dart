/// Public-facing part of a Docmac identity. Private contact details remain in
/// the owner-only `users/{uid}` document.
class PublicProfile {
  const PublicProfile({
    required this.uid,
    required this.username,
    required this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String username;
  final String displayName;
  final String? photoUrl;

  String get initial {
    if (displayName.isNotEmpty) return displayName[0].toUpperCase();
    if (username.isNotEmpty) return username[0].toUpperCase();
    return '?';
  }

  factory PublicProfile.fromMap(String uid, Map<String, dynamic> map) {
    final username = (map['username'] ?? '').toString();
    final displayName = (map['displayName'] ?? username).toString();
    return PublicProfile(
      uid: uid,
      username: username,
      displayName: displayName.isEmpty ? username : displayName,
      photoUrl: map['photoUrl'] is String ? map['photoUrl'] as String : null,
    );
  }
}
