import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/person_profile.dart';
import '../../data/repositories/people_repository.dart';

class OrbitPulse {
  const OrbitPulse({
    required this.momentsCount,
    required this.nearbyCount,
  });

  final int momentsCount;
  final int nearbyCount;
}

final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  return InMemoryPeopleRepository();
});

final allPeopleProvider = Provider<List<PersonProfile>>((ref) {
  final repo = ref.watch(peopleRepositoryProvider);
  return repo.getAll();
});

final innerOrbitPeopleProvider = Provider<List<PersonProfile>>((ref) {
  final all = ref.watch(allPeopleProvider);
  return all.take(5).toList();
});

final activeNowPeopleProvider = Provider<List<PersonProfile>>((ref) {
  final all = ref.watch(allPeopleProvider);
  return all.where((p) => p.isOnline).toList();
});

final orbitPulseProvider = Provider<OrbitPulse>((ref) {
  final all = ref.watch(allPeopleProvider);
  final nearby = all.where((p) => p.isNearby).length;
  return OrbitPulse(
    momentsCount: 5,
    nearbyCount: nearby,
  );
});

final personByIdProvider = Provider.family<PersonProfile?, String>((ref, id) {
  final repo = ref.watch(peopleRepositoryProvider);
  return repo.getById(id);
});

