import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/call_record.dart';
import '../../data/repositories/call_repository.dart';

enum CallFilter { all, favorites, missed }

final callRepositoryProvider = Provider<CallRepository>((ref) {
  return PersistentCallRepository();
});

final callFilterProvider = StateProvider<CallFilter>((ref) => CallFilter.all);

class CallNotifier extends StateNotifier<AsyncValue<List<CallRecord>>> {
  CallNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCalls();
  }

  final CallRepository _repository;

  Future<void> loadCalls() async {
    try {
      final calls = await _repository.getCalls();
      if (!mounted) return;
      state = AsyncValue.data(calls);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logOutgoingCall({
    required String target,
    String? displayName,
    bool isVideo = false,
  }) async {
    final cleanTarget = target.trim();
    final isPhone = RegExp(r'^[0-9+()\-\s]+$').hasMatch(cleanTarget);
    final name = displayName ?? (isPhone ? cleanTarget : cleanTarget);
    final initial = isPhone ? '#' : name.substring(0, 1).toUpperCase();

    final record = CallRecord(
      id: 'call-${DateTime.now().millisecondsSinceEpoch}',
      personId: cleanTarget,
      name: name,
      initial: initial,
      detail: isVideo ? 'Outgoing video signal' : 'Outgoing voice signal',
      when: 'Just now',
      tintValue: 0xFF0D70EC,
      video: isVideo,
      missed: false,
      favorite: false,
      isOutgoing: true,
      timestamp: DateTime.now(),
    );

    await _repository.logCall(record);
    await loadCalls();
  }

  Future<void> toggleFavorite(String callId) async {
    await _repository.toggleFavorite(callId);
    await loadCalls();
  }

  Future<void> deleteCall(String callId) async {
    await _repository.deleteCall(callId);
    await loadCalls();
  }
}

final callsNotifierProvider =
    StateNotifierProvider<CallNotifier, AsyncValue<List<CallRecord>>>((ref) {
  final repo = ref.watch(callRepositoryProvider);
  return CallNotifier(repo);
});

final filteredCallsProvider = Provider<List<CallRecord>>((ref) {
  final callsAsync = ref.watch(callsNotifierProvider);
  final filter = ref.watch(callFilterProvider);

  return callsAsync.maybeWhen(
    data: (calls) => calls.where((call) {
      if (filter == CallFilter.favorites && !call.favorite) return false;
      if (filter == CallFilter.missed && !call.missed) return false;
      return true;
    }).toList(),
    orElse: () => PersistentCallRepository.initialSeeds.where((call) {
      if (filter == CallFilter.favorites && !call.favorite) return false;
      if (filter == CallFilter.missed && !call.missed) return false;
      return true;
    }).toList(),
  );
});
