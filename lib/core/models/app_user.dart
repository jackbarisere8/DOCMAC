class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.createdAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime? createdAt;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
