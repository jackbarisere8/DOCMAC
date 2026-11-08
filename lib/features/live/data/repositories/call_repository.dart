import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/feature_flags.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/call_record.dart';

abstract class CallRepository {
  Future<List<CallRecord>> getCalls();
  Future<void> logCall(CallRecord record);
  Future<void> toggleFavorite(String callId);
  Future<void> deleteCall(String callId);
  Future<void> clearAll();
}

class PersistentCallRepository implements CallRepository {
  PersistentCallRepository({SharedPreferences? preferences})
      : _preferences = preferences;

  SharedPreferences? _preferences;
  static const _storageKey = 'docmac_live_call_records_v1';

  Future<SharedPreferences> _getPrefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  static List<CallRecord> get initialSeeds => !AppFeatureFlags.localPreviews
      ? const <CallRecord>[]
      : [
          CallRecord(
            id: 'seed-1',
            personId: 'emma',
            name: 'Emma Clarke',
            initial: 'E',
            detail: 'Voice signal · 18 min',
            when: '6:21 PM',
            tintValue: AppColors.accent.toARGB32(),
            favorite: true,
            durationSeconds: 1080,
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          CallRecord(
            id: 'seed-2',
            personId: 'david',
            name: 'David Okafor',
            initial: 'D',
            detail: 'Missed video signal',
            when: '4:40 PM',
            tintValue: 0xFFD9E9F8,
            video: true,
            missed: true,
            timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          ),
          CallRecord(
            id: 'seed-3',
            personId: 'tobi',
            name: 'Tobi Adeyemi',
            initial: 'T',
            detail: 'Voice signal · 42 min',
            when: 'Yesterday',
            tintValue: 0xFFE6DFEF,
            favorite: true,
            durationSeconds: 2520,
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
          ),
          CallRecord(
            id: 'seed-4',
            personId: 'jack',
            name: 'Jack Wilson',
            initial: 'J',
            detail: 'Voice signal · 6 min',
            when: 'Mon',
            tintValue: 0xFFF5E6C8,
            durationSeconds: 360,
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ];

  @override
  Future<List<CallRecord>> getCalls() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      final seeds = initialSeeds;
      await _saveCalls(seeds, prefs);
      return seeds;
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded
          .map((item) => CallRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return initialSeeds;
    }
  }

  Future<void> _saveCalls(List<CallRecord> calls,
      [SharedPreferences? prefs]) async {
    final storage = prefs ?? await _getPrefs();
    final encoded = jsonEncode(calls.map((c) => c.toJson()).toList());
    await storage.setString(_storageKey, encoded);
  }

  @override
  Future<void> logCall(CallRecord record) async {
    final calls = await getCalls();
    // Insert at front of history
    final updated = [record, ...calls];
    await _saveCalls(updated);
  }

  @override
  Future<void> toggleFavorite(String callId) async {
    final calls = await getCalls();
    final updated = calls.map((c) {
      if (c.id == callId) {
        return c.copyWith(favorite: !c.favorite);
      }
      return c;
    }).toList();
    await _saveCalls(updated);
  }

  @override
  Future<void> deleteCall(String callId) async {
    final calls = await getCalls();
    final updated = calls.where((c) => c.id != callId).toList();
    await _saveCalls(updated);
  }

  @override
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.remove(_storageKey);
  }
}
