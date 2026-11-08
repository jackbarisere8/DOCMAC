import 'package:flutter/material.dart';

/// A person in the social side of Docmac.
///
/// Social people are intentionally separate from [ContactProfile]: they can
/// follow you, appear in Discover and open a public profile, but they only get
/// a Talk button once they also exist in the address book.
class ConnectionProfile {
  const ConnectionProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.initials,
    required this.detail,
    required this.avatarTint,
    this.followsYou = false,
    this.youFollow = false,
    this.isContact = false,
    this.isOnline = false,
  });

  final String id;
  final String name;
  final String username;
  final String initials;
  final String detail;
  final int avatarTint;
  final bool followsYou;
  final bool youFollow;

  /// True when this person is also saved in the phone address book. That is
  /// the only state that unlocks a private Talk from a follower row.
  final bool isContact;
  final bool isOnline;

  Color get tint => Color(avatarTint);

  String get shortName => name.split(' ').first;

  ConnectionProfile copyWith({
    String? id,
    String? name,
    String? username,
    String? initials,
    String? detail,
    int? avatarTint,
    bool? followsYou,
    bool? youFollow,
    bool? isContact,
    bool? isOnline,
  }) {
    return ConnectionProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      initials: initials ?? this.initials,
      detail: detail ?? this.detail,
      avatarTint: avatarTint ?? this.avatarTint,
      followsYou: followsYou ?? this.followsYou,
      youFollow: youFollow ?? this.youFollow,
      isContact: isContact ?? this.isContact,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// A phone address-book entry. Contacts are the people who can be messaged;
/// people without a Docmac account can only be invited.
class ContactProfile {
  const ContactProfile({
    required this.id,
    required this.name,
    required this.initials,
    required this.phone,
    required this.avatarTint,
    this.username,
    this.note,
    this.isOnDocmac = false,
    this.isOnline = false,
    this.invited = false,
  });

  final String id;
  final String name;
  final String initials;
  final String phone;
  final String? username;
  final String? note;
  final int avatarTint;
  final bool isOnDocmac;
  final bool isOnline;
  final bool invited;

  Color get tint => Color(avatarTint);

  String get shortName => name.split(' ').first;

  ContactProfile copyWith({
    String? id,
    String? name,
    String? initials,
    String? phone,
    String? username,
    String? note,
    int? avatarTint,
    bool? isOnDocmac,
    bool? isOnline,
    bool? invited,
  }) {
    return ContactProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      note: note ?? this.note,
      avatarTint: avatarTint ?? this.avatarTint,
      isOnDocmac: isOnDocmac ?? this.isOnDocmac,
      isOnline: isOnline ?? this.isOnline,
      invited: invited ?? this.invited,
    );
  }
}
