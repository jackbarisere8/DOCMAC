import 'package:docmac_app/features/live/data/models/call_record.dart';
import 'package:docmac_app/features/live/data/repositories/call_repository.dart';
import 'package:docmac_app/features/live/presentation/providers/live_providers.dart';
import 'package:docmac_app/features/people/data/repositories/people_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Call Engine & Repository Tests', () {
    test('PersistentCallRepository initializes seeds when cache is empty',
        () async {
      final repo = PersistentCallRepository();
      final calls = await repo.getCalls();

      expect(calls, isNotEmpty);
      expect(calls.any((c) => c.personId == 'emma'), isTrue);
    });

    test('PersistentCallRepository logs and persists outgoing call', () async {
      final repo = PersistentCallRepository();
      final newCall = CallRecord(
        id: 'test-call-1',
        personId: '+15550199',
        name: '+15550199',
        initial: '#',
        detail: 'Outgoing voice signal',
        when: 'Just now',
        tintValue: 0xFF0D70EC,
        isOutgoing: true,
        timestamp: DateTime.now(),
      );

      await repo.logCall(newCall);
      final calls = await repo.getCalls();

      expect(calls.first.id, 'test-call-1');
      expect(calls.first.personId, '+15550199');
      expect(calls.first.isOutgoing, isTrue);
    });

    test('PersistentCallRepository toggles favorite status correctly',
        () async {
      final repo = PersistentCallRepository();
      final calls = await repo.getCalls();
      final target = calls.first;
      final originalFavorite = target.favorite;

      await repo.toggleFavorite(target.id);
      final updatedCalls = await repo.getCalls();
      final updated = updatedCalls.firstWhere((c) => c.id == target.id);

      expect(updated.favorite, !originalFavorite);
    });

    test('CallNotifier manages reactive state transitions', () async {
      final repo = PersistentCallRepository();
      final notifier = CallNotifier(repo);
      addTearDown(notifier.dispose);

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(notifier.state.hasValue, isTrue);

      await notifier.logOutgoingCall(
        target: 'tobi',
        displayName: 'Tobi Adeyemi',
      );

      expect(notifier.state.value?.first.personId, 'tobi');
    });
  });

  group('People & Social Graph Domain Tests', () {
    test('InMemoryPeopleRepository returns unified roster', () {
      final repo = InMemoryPeopleRepository();
      final people = repo.getAll();

      expect(people.length, greaterThanOrEqualTo(5));
      expect(people.any((p) => p.id == 'emma'), isTrue);
      expect(people.any((p) => p.id == 'jack'), isTrue);
    });

    test('InMemoryPeopleRepository finds person by ID case-insensitively', () {
      final repo = InMemoryPeopleRepository();
      final personUpper = repo.getById('EMMA');
      final personLower = repo.getById('emma');

      expect(personUpper, isNotNull);
      expect(personUpper?.name, 'Emma Clarke');
      expect(personUpper?.id, personLower?.id);
    });

    test('InMemoryPeopleRepository updates status and notifies stream',
        () async {
      final repo = InMemoryPeopleRepository();
      final futureUpdate = repo.watchPeople().first;

      await repo.updateStatus('emma', 'Recording a voice note');
      final updatedRoster = await futureUpdate;
      final emma = updatedRoster.firstWhere((p) => p.id == 'emma');

      expect(emma.status, 'Recording a voice note');
    });
  });
}

