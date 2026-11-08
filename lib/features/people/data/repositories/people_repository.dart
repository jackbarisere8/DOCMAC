import 'dart:async';

import '../../../../config/feature_flags.dart';
import '../models/person_profile.dart';

abstract class PeopleRepository {
  List<PersonProfile> getAll();
  PersonProfile? getById(String id);
  Stream<List<PersonProfile>> watchPeople();
  Future<void> updateStatus(String id, String status);
}

class InMemoryPeopleRepository implements PeopleRepository {
  InMemoryPeopleRepository() {
    // Release builds have no real people discovery yet, so they must not
    // invent a roster. Debug and tests keep the sample roster for design work.
    _people = AppFeatureFlags.localPreviews
        ? List.of(_defaultRoster)
        : <PersonProfile>[];
  }

  static const List<PersonProfile> _defaultRoster = [
    PersonProfile(
      id: 'emma',
      name: 'Emma Clarke',
      initials: 'EC',
      status: 'Available',
      bio: 'Reading, cooking and the occasional long walk.',
      isOnline: true,
      isNearby: true,
      avatarTint: 0xFF5856D6,
      circle: 'Weekend plans',
    ),
    PersonProfile(
      id: 'jack',
      name: 'Jack Wilson',
      initials: 'JW',
      status: 'Taking the scenic route home.',
      bio: 'Always exploring, learning, and building.',
      isOnline: true,
      isNearby: true,
      avatarTint: 0xFFF5E6C8,
      circle: 'Design club',
    ),
    PersonProfile(
      id: 'david',
      name: 'David Okafor',
      initials: 'DO',
      status: 'Quiet · In a flow state',
      bio: 'Making thoughtful things with good people.',
      isOnline: false,
      isNearby: false,
      avatarTint: 0xFFD9E9F8,
      circle: 'Weekend plans',
    ),
    PersonProfile(
      id: 'davidm',
      name: 'David Mensah',
      initials: 'DM',
      status: 'Design Circle',
      bio: 'Exploring spatial interfaces and tactile typography.',
      isOnline: false,
      isNearby: false,
      avatarTint: 0xFFD9E9F8,
      circle: 'Design club',
    ),
    PersonProfile(
      id: 'amara',
      name: 'Amara Okafor',
      initials: 'AO',
      status: 'Active 12m ago',
      bio: 'Exploring, learning, and building every day.',
      isOnline: true,
      isNearby: true,
      avatarTint: 0xFF34C759,
      circle: 'Music room',
    ),
    PersonProfile(
      id: 'noraw',
      name: 'Nora Williams',
      initials: 'NW',
      status: 'Sunday Notes',
      bio: 'Writing, thinking, and finding the right words.',
      isOnline: false,
      isNearby: false,
      avatarTint: 0xFFFF9500,
      circle: 'Design club',
    ),
    PersonProfile(
      id: 'tobi',
      name: 'Tobi Adeyemi',
      initials: 'TA',
      status: 'Always up for a new idea.',
      bio: 'Product engineer & music enthusiast.',
      isOnline: false,
      isNearby: false,
      avatarTint: 0xFFE6DFEF,
      circle: 'Music room',
    ),
  ];

  late List<PersonProfile> _people;
  final _controller = StreamController<List<PersonProfile>>.broadcast();

  @override
  List<PersonProfile> getAll() => List.unmodifiable(_people);

  @override
  PersonProfile? getById(String id) {
    try {
      return _people.firstWhere((p) => p.id.toLowerCase() == id.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<PersonProfile>> watchPeople() {
    return _controller.stream;
  }

  @override
  Future<void> updateStatus(String id, String status) async {
    _people = _people.map((p) {
      if (p.id.toLowerCase() == id.toLowerCase()) {
        return p.copyWith(status: status);
      }
      return p;
    }).toList();
    _controller.add(List.unmodifiable(_people));
  }

  void dispose() {
    _controller.close();
  }
}
