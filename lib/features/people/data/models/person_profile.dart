import 'package:flutter/material.dart';

class PersonProfile {
  const PersonProfile({
    required this.id,
    required this.name,
    required this.initials,
    required this.status,
    required this.bio,
    this.isOnline = false,
    this.isNearby = false,
    this.avatarTint = 0xFF0D70EC,
    this.avatarUrl,
    this.circle,
  });

  final String id;
  final String name;
  final String initials;
  final String status;
  final String bio;
  final bool isOnline;
  final bool isNearby;
  final int avatarTint;
  final String? avatarUrl;
  final String? circle;

  Color get tint => Color(avatarTint);

  String get shortName => name.split(' ').first;

  PersonProfile copyWith({
    String? id,
    String? name,
    String? initials,
    String? status,
    String? bio,
    bool? isOnline,
    bool? isNearby,
    int? avatarTint,
    String? avatarUrl,
    String? circle,
  }) {
    return PersonProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      status: status ?? this.status,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,
      isNearby: isNearby ?? this.isNearby,
      avatarTint: avatarTint ?? this.avatarTint,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      circle: circle ?? this.circle,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initials': initials,
        'status': status,
        'bio': bio,
        'isOnline': isOnline,
        'isNearby': isNearby,
        'avatarTint': avatarTint,
        'avatarUrl': avatarUrl,
        'circle': circle,
      };

  factory PersonProfile.fromJson(Map<String, dynamic> json) => PersonProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        initials: json['initials'] as String,
        status: json['status'] as String,
        bio: json['bio'] as String,
        isOnline: json['isOnline'] as bool? ?? false,
        isNearby: json['isNearby'] as bool? ?? false,
        avatarTint: json['avatarTint'] as int? ?? 0xFF0D70EC,
        avatarUrl: json['avatarUrl'] as String?,
        circle: json['circle'] as String?,
      );
}
