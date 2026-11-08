import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/feature_flags.dart';
import 'models/connection_profile.dart';

/// Immutable snapshot of the two circles Docmac keeps apart:
///
/// * **Social** — followers, people you follow and incoming follow requests.
/// * **Address book** — phone contacts and which of them are on Docmac.
class ConnectionsState {
  const ConnectionsState({
    required this.followers,
    required this.following,
    required this.requests,
    required this.contacts,
    this.likes = 0,
  });

  final List<ConnectionProfile> followers;
  final List<ConnectionProfile> following;
  final List<ConnectionProfile> requests;
  final List<ContactProfile> contacts;

  /// Public seen count. Docmac counts how many times your moments were seen.
  final int likes;

  /// The Docmac name for seen counts, used across profile surfaces.
  int get seen => likes;

  int get followerCount => followers.length;
  int get followingCount => following.length;
  int get requestCount => requests.length;
  int get contactCount => contacts.length;
  int get onDocmacContactCount =>
      contacts.where((contact) => contact.isOnDocmac).length;

  List<ContactProfile> get onDocmacContacts =>
      contacts.where((contact) => contact.isOnDocmac).toList(growable: false);
  List<ContactProfile> get inviteContacts =>
      contacts.where((contact) => !contact.isOnDocmac).toList(growable: false);

  ConnectionProfile? followerById(String id) =>
      followers.where((person) => person.id == id).firstOrNull;

  ConnectionProfile? followingById(String id) =>
      following.where((person) => person.id == id).firstOrNull;

  ContactProfile? contactById(String id) =>
      contacts.where((contact) => contact.id == id).firstOrNull;

  ConnectionsState copyWith({
    List<ConnectionProfile>? followers,
    List<ConnectionProfile>? following,
    List<ConnectionProfile>? requests,
    List<ContactProfile>? contacts,
    int? likes,
  }) {
    return ConnectionsState(
      followers: followers ?? this.followers,
      following: following ?? this.following,
      requests: requests ?? this.requests,
      contacts: contacts ?? this.contacts,
      likes: likes ?? this.likes,
    );
  }
}

/// Small in-memory controller for the prototype. It keeps profile stats,
/// requests and contact actions in sync across every surface in the app.
class ConnectionsController extends ValueNotifier<ConnectionsState> {
  ConnectionsController._(super.value);

  factory ConnectionsController.seeded() {
    return ConnectionsController._(_seedState());
  }

  /// Accepting a follow request makes the relationship mutual. It also means
  /// the person can now appear in the follower and following lists.
  void acceptRequest(String id) {
    final request =
        value.requests.where((person) => person.id == id).firstOrNull;
    if (request == null) return;

    final accepted = request.copyWith(
      followsYou: true,
      youFollow: true,
    );
    final followers = [
      accepted,
      ...value.followers.where((person) => person.id != id),
    ];
    final following = [
      accepted,
      ...value.following.where((person) => person.id != id),
    ];
    value = value.copyWith(
      followers: List.unmodifiable(followers),
      following: List.unmodifiable(following),
      requests: List.unmodifiable(
        value.requests.where((person) => person.id != id),
      ),
    );
  }

  void ignoreRequest(String id) {
    value = value.copyWith(
      requests: List.unmodifiable(
        value.requests.where((person) => person.id != id),
      ),
    );
  }

  /// Follow or unfollow someone from the social lists. The follower cards and
  /// profile stats both read from this single source of truth.
  void toggleFollow(ConnectionProfile person) {
    final alreadyFollowing =
        value.following.any((item) => item.id == person.id);

    final following = alreadyFollowing
        ? value.following.where((item) => item.id != person.id).toList()
        : [
            person.copyWith(youFollow: true),
            ...value.following.where((item) => item.id != person.id),
          ];

    final followers = value.followers
        .map(
          (item) => item.id == person.id
              ? item.copyWith(youFollow: !alreadyFollowing)
              : item,
        )
        .toList(growable: false);

    value = value.copyWith(
      following: List.unmodifiable(following),
      followers: List.unmodifiable(followers),
    );
  }

  void inviteContact(String id) {
    value = value.copyWith(
      contacts: List.unmodifiable(
        value.contacts.map(
          (contact) =>
              contact.id == id ? contact.copyWith(invited: true) : contact,
        ),
      ),
    );
  }

  static ConnectionsState _seedState() {
    // There is no real social graph or address-book sync yet. Release builds
    // must show honest empty lists instead of inventing followers, requests,
    // phone numbers, and a seen count.
    if (!AppFeatureFlags.localPreviews) {
      return const ConnectionsState(
        followers: [],
        following: [],
        requests: [],
        contacts: [],
        likes: 0,
      );
    }

    const amara = ConnectionProfile(
      id: 'amara',
      name: 'Amara Okafor',
      username: 'amara',
      initials: 'AO',
      detail: 'Music room · Uyo',
      avatarTint: 0xFF2E9F76,
      followsYou: true,
      youFollow: true,
      isContact: true,
      isOnline: true,
    );
    const tobi = ConnectionProfile(
      id: 'tobi',
      name: 'Tobi Adeyemi',
      username: 'tobi',
      initials: 'TA',
      detail: 'Product engineer · Lagos',
      avatarTint: 0xFF7C6BFF,
      followsYou: true,
      youFollow: true,
      isContact: true,
    );
    const maya = ConnectionProfile(
      id: 'mayac',
      name: 'Maya Chen',
      username: 'mayac',
      initials: 'MC',
      detail: 'Product Circle · Singapore',
      avatarTint: 0xFF17A6A0,
      followsYou: true,
      youFollow: true,
      isContact: true,
      isOnline: true,
    );
    const emma = ConnectionProfile(
      id: 'emma',
      name: 'Emma Clarke',
      username: 'emma',
      initials: 'EC',
      detail: 'Weekend plans · London',
      avatarTint: 0xFF4A6CF7,
      followsYou: true,
      youFollow: true,
      isContact: true,
      isOnline: true,
    );
    const david = ConnectionProfile(
      id: 'davidm',
      name: 'David Mensah',
      username: 'davidm',
      initials: 'DM',
      detail: 'Design Circle · Accra',
      avatarTint: 0xFF5B8DEF,
      followsYou: true,
      isContact: true,
    );
    const nora = ConnectionProfile(
      id: 'noraw',
      name: 'Nora Williams',
      username: 'noraw',
      initials: 'NW',
      detail: 'Sunday Notes · Cape Town',
      avatarTint: 0xFFE09A2E,
      followsYou: true,
    );
    const sofia = ConnectionProfile(
      id: 'sofiar',
      name: 'Sofia Reyes',
      username: 'sofiar',
      initials: 'SR',
      detail: 'Product Circle · Madrid',
      avatarTint: 0xFFB26BFF,
      followsYou: true,
      youFollow: true,
    );
    const noah = ConnectionProfile(
      id: 'noahk',
      name: 'Noah Kim',
      username: 'noahk',
      initials: 'NK',
      detail: 'Shared Space · Design',
      avatarTint: 0xFF3AA7E0,
      followsYou: true,
      youFollow: true,
    );
    const liam = ConnectionProfile(
      id: 'liamb',
      name: 'Liam Brooks',
      username: 'liamb',
      initials: 'LB',
      detail: 'Met through Docmac',
      avatarTint: 0xFFE0657B,
      followsYou: true,
      isContact: true,
    );
    const kofi = ConnectionProfile(
      id: 'kofim',
      name: 'Kofi Mensah',
      username: 'kofim',
      initials: 'KM',
      detail: 'Afro Tech · Kumasi',
      avatarTint: 0xFFD9A441,
      followsYou: true,
    );
    const hana = ConnectionProfile(
      id: 'hanai',
      name: 'Hana Ito',
      username: 'hanai',
      initials: 'HI',
      detail: 'Design Circle · Kyoto',
      avatarTint: 0xFFE0657B,
      followsYou: true,
      youFollow: true,
    );
    const zara = ConnectionProfile(
      id: 'zarab',
      name: 'Zara Bello',
      username: 'zarab',
      initials: 'ZB',
      detail: 'Sunday Notes · Abuja',
      avatarTint: 0xFF2F6BFF,
      followsYou: true,
    );
    const jack = ConnectionProfile(
      id: 'jack',
      name: 'Jack Wilson',
      username: 'jack',
      initials: 'JW',
      detail: 'Design club · Uyo',
      avatarTint: 0xFFC79552,
      youFollow: true,
      isContact: true,
      isOnline: true,
    );

    const ifeoma = ConnectionProfile(
      id: 'ifeomao',
      name: 'Ifeoma Obi',
      username: 'ifeomao',
      initials: 'IO',
      detail: 'In your contacts · 2 mutual links',
      avatarTint: 0xFF8D6E63,
      followsYou: true,
      isContact: true,
    );
    const bashir = ConnectionProfile(
      id: 'bashirl',
      name: 'Bashir Lawal',
      username: 'bashirl',
      initials: 'BL',
      detail: 'Met in Design Circle',
      avatarTint: 0xFF5E8D6A,
      followsYou: true,
    );

    const contacts = [
      ContactProfile(
        id: 'jack',
        name: 'Jack Wilson',
        initials: 'JW',
        phone: '+234 803 555 0142',
        username: 'jack',
        note: 'Design club',
        avatarTint: 0xFFC79552,
        isOnDocmac: true,
        isOnline: true,
      ),
      ContactProfile(
        id: 'amara',
        name: 'Amara Okafor',
        initials: 'AO',
        phone: '+234 806 555 0138',
        username: 'amara',
        note: 'Music room',
        avatarTint: 0xFF2E9F76,
        isOnDocmac: true,
        isOnline: true,
      ),
      ContactProfile(
        id: 'emma',
        name: 'Emma Clarke',
        initials: 'EC',
        phone: '+44 7700 900123',
        username: 'emma',
        note: 'Weekend plans',
        avatarTint: 0xFF4A6CF7,
        isOnDocmac: true,
        isOnline: true,
      ),
      ContactProfile(
        id: 'davidm',
        name: 'David Mensah',
        initials: 'DM',
        phone: '+233 24 555 0198',
        username: 'davidm',
        note: 'Design Circle',
        avatarTint: 0xFF5B8DEF,
        isOnDocmac: true,
      ),
      ContactProfile(
        id: 'tobi',
        name: 'Tobi Adeyemi',
        initials: 'TA',
        phone: '+234 809 555 0117',
        username: 'tobi',
        note: 'Music room',
        avatarTint: 0xFF7C6BFF,
        isOnDocmac: true,
      ),
      ContactProfile(
        id: 'mayac',
        name: 'Maya Chen',
        initials: 'MC',
        phone: '+1 415 555 0164',
        username: 'mayac',
        note: 'Product Circle',
        avatarTint: 0xFF17A6A0,
        isOnDocmac: true,
        isOnline: true,
      ),
      ContactProfile(
        id: 'liamb',
        name: 'Liam Brooks',
        initials: 'LB',
        phone: '+1 212 555 0189',
        username: 'liamb',
        note: 'Met through Docmac',
        avatarTint: 0xFFE0657B,
        isOnDocmac: true,
      ),
      ContactProfile(
        id: 'ifeomao',
        name: 'Ifeoma Obi',
        initials: 'IO',
        phone: '+234 802 555 0199',
        username: 'ifeomao',
        note: 'Family friend',
        avatarTint: 0xFF8D6E63,
        isOnDocmac: true,
      ),
      ContactProfile(
        id: 'ngozi',
        name: 'Mama Ngozi',
        initials: 'MN',
        phone: '+234 803 555 0100',
        note: 'Family',
        avatarTint: 0xFFD9A441,
      ),
      ContactProfile(
        id: 'daniel',
        name: 'Daniel Eze',
        initials: 'DE',
        phone: '+234 805 555 0177',
        note: 'Work',
        avatarTint: 0xFF3AA7E0,
      ),
      ContactProfile(
        id: 'blessing',
        name: 'Blessing Udo',
        initials: 'BU',
        phone: '+234 807 555 0161',
        note: 'Church',
        avatarTint: 0xFFB26BFF,
      ),
    ];

    return const ConnectionsState(
      followers: [
        amara,
        tobi,
        maya,
        emma,
        david,
        nora,
        sofia,
        noah,
        liam,
        kofi,
        hana,
        zara,
      ],
      following: [amara, tobi, maya, emma, sofia, noah, hana, jack],
      requests: [ifeoma, bashir],
      contacts: contacts,
      likes: 2779,
    );
  }
}

final connectionsProvider = Provider<ConnectionsController>((ref) {
  final controller = ConnectionsController.seeded();
  ref.onDispose(controller.dispose);
  return controller;
});
