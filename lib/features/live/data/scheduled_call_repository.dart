import 'package:cloud_firestore/cloud_firestore.dart';

/// The durable representation of a scheduled Docmac signal.
///
/// Reminder delivery is deliberately represented as data rather than performed
/// from the client. A trusted server worker can safely fan this out to invitees
/// at [reminderAt] without relying on a device being online.
class ScheduledCallDraft {
  const ScheduledCallDraft({
    required this.title,
    required this.note,
    required this.startsAt,
    required this.endsAt,
    required this.isVideo,
    required this.inviteeNames,
    required this.reminderEnabled,
  });

  final String title;
  final String note;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isVideo;
  final List<String> inviteeNames;
  final bool reminderEnabled;
}

class ScheduledCallRepository {
  ScheduledCallRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<String> create({
    required String organizerId,
    required ScheduledCallDraft draft,
  }) async {
    final startsAt = Timestamp.fromDate(draft.startsAt);
    final endsAt = Timestamp.fromDate(draft.endsAt);
    final reminderAt = Timestamp.fromDate(
      draft.startsAt.subtract(const Duration(minutes: 15)),
    );
    final document = await _firestore.collection('callSchedules').add({
      'organizerId': organizerId,
      'title': draft.title,
      'note': draft.note,
      'startsAt': startsAt,
      'endsAt': endsAt,
      'callType': draft.isVideo ? 'video' : 'voice',
      'inviteeNames': draft.inviteeNames,
      'reminderEnabled': draft.reminderEnabled,
      'reminderAt': reminderAt,
      'status': 'scheduled',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return document.id;
  }
}
