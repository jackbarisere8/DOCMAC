import 'package:flutter/material.dart';

enum CallType { voice, video }

enum CallDirection { incoming, outgoing, missed }

class CallRecord {
  const CallRecord({
    required this.id,
    required this.personId,
    required this.name,
    required this.initial,
    required this.detail,
    required this.when,
    required this.tintValue,
    this.video = false,
    this.missed = false,
    this.favorite = false,
    this.isOutgoing = false,
    this.durationSeconds = 0,
    required this.timestamp,
  });

  final String id;
  final String personId;
  final String name;
  final String initial;
  final String detail;
  final String when;
  final int tintValue;
  final bool video;
  final bool missed;
  final bool favorite;
  final bool isOutgoing;
  final int durationSeconds;
  final DateTime timestamp;

  Color get tint => Color(tintValue);

  CallRecord copyWith({
    String? id,
    String? personId,
    String? name,
    String? initial,
    String? detail,
    String? when,
    int? tintValue,
    bool? video,
    bool? missed,
    bool? favorite,
    bool? isOutgoing,
    int? durationSeconds,
    DateTime? timestamp,
  }) {
    return CallRecord(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      name: name ?? this.name,
      initial: initial ?? this.initial,
      detail: detail ?? this.detail,
      when: when ?? this.when,
      tintValue: tintValue ?? this.tintValue,
      video: video ?? this.video,
      missed: missed ?? this.missed,
      favorite: favorite ?? this.favorite,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'personId': personId,
        'name': name,
        'initial': initial,
        'detail': detail,
        'when': when,
        'tintValue': tintValue,
        'video': video,
        'missed': missed,
        'favorite': favorite,
        'isOutgoing': isOutgoing,
        'durationSeconds': durationSeconds,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CallRecord.fromJson(Map<String, dynamic> json) {
    return CallRecord(
      id: json['id'] as String,
      personId: json['personId'] as String,
      name: json['name'] as String,
      initial: json['initial'] as String,
      detail: json['detail'] as String,
      when: json['when'] as String,
      tintValue: json['tintValue'] as int? ?? 0xFF0D70EC,
      video: json['video'] as bool? ?? false,
      missed: json['missed'] as bool? ?? false,
      favorite: json['favorite'] as bool? ?? false,
      isOutgoing: json['isOutgoing'] as bool? ?? false,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

