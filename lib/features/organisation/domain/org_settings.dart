import 'package:flutter/foundation.dart';

import '../../../shared/models/firestore_converters.dart';

/// Working hours of the organisation (`orgs/{org}.workingHours`).
/// [start] and [end] are `HH:mm` (24-hour, organisation time zone);
/// [days] are ISO weekdays, 1 = Monday ... 7 = Sunday.
@immutable
class WorkingHours {
  const WorkingHours({
    required this.start,
    required this.end,
    required this.days,
  });

  factory WorkingHours.fromMap(Object? raw) {
    final map = raw is Map
        ? raw.cast<String, Object?>()
        : const <String, Object?>{};
    return WorkingHours(
      start: FirestoreConverters.stringOrNull(map['start']) ?? defaults.start,
      end: FirestoreConverters.stringOrNull(map['end']) ?? defaults.end,
      days: map['days'] is List
          ? (map['days']! as List)
                .whereType<num>()
                .map((d) => d.toInt())
                .toList()
          : defaults.days,
    );
  }

  /// Defaults used only for display when a field is missing.
  static const WorkingHours defaults = WorkingHours(
    start: '08:00',
    end: '17:00',
    days: [1, 2, 3, 4, 5],
  );

  final String start;
  final String end;
  final List<int> days;

  Map<String, Object?> toMap() => {
    'start': start,
    'end': end,
    'days': [...days]..sort(),
  };

  @override
  bool operator ==(Object other) =>
      other is WorkingHours &&
      other.start == start &&
      other.end == end &&
      setEquals(other.days.toSet(), days.toSet());

  @override
  int get hashCode =>
      Object.hash(start, end, Object.hashAllUnordered(days.toSet()));
}

/// The settings an admin edits in `orgs/{org}` (spec 4.2, 4.5, 4.6).
///
/// Only fields the Security Rules let a verified admin change are written
/// (see [changedFields]); the time zone is shown but not edited.
@immutable
class OrgSettings {
  const OrgSettings({
    required this.name,
    required this.timezone,
    required this.workingHoursEnabled,
    required this.workingHours,
    required this.reminderHours,
    required this.escalationHours,
    required this.escalationMaxLevel,
    required this.smsEnabled,
    required this.smsMonthlyCap,
  });

  factory OrgSettings.fromMap(Map<String, Object?> map) => OrgSettings(
    name: FirestoreConverters.stringOrNull(map['name']) ?? '',
    timezone:
        FirestoreConverters.stringOrNull(map['timezone']) ?? defaultTimezone,
    workingHoursEnabled: FirestoreConverters.boolOr(
      map['workingHoursEnabled'],
      false,
    ),
    workingHours: WorkingHours.fromMap(map['workingHours']),
    reminderHours: map['reminderHours'] is List
        ? (map['reminderHours']! as List)
              .whereType<num>()
              .map((h) => h.toInt())
              .toList()
        : const [24, 1],
    escalationHours: FirestoreConverters.intOr(map['escalationHours'], 24),
    escalationMaxLevel: FirestoreConverters.intOr(map['escalationMaxLevel'], 2),
    smsEnabled: FirestoreConverters.boolOr(map['smsEnabled'], false),
    smsMonthlyCap: FirestoreConverters.intOr(map['smsMonthlyCap'], 0),
  );

  /// East Africa Time (spec 4.2).
  static const String defaultTimezone = 'Africa/Dar_es_Salaam';

  /// Reasonable limits for the form. The server stores whatever the rules
  /// allow; these only stop typing mistakes.
  static const int maxHours = 720; // 30 days
  static const int maxEscalationLevel = 10;

  final String name;
  final String timezone;
  final bool workingHoursEnabled;
  final WorkingHours workingHours;

  /// Hours before the deadline when reminders are sent, e.g. [24, 1].
  final List<int> reminderHours;

  /// Hours after the deadline before escalating (default 24).
  final int escalationHours;

  /// How many levels up the reporting line escalation climbs (default 2).
  final int escalationMaxLevel;
  final bool smsEnabled;

  /// Monthly SMS spending cap in TZS.
  final int smsMonthlyCap;

  OrgSettings copyWith({
    bool? workingHoursEnabled,
    WorkingHours? workingHours,
    List<int>? reminderHours,
    int? escalationHours,
    int? escalationMaxLevel,
    bool? smsEnabled,
    int? smsMonthlyCap,
  }) => OrgSettings(
    name: name,
    timezone: timezone,
    workingHoursEnabled: workingHoursEnabled ?? this.workingHoursEnabled,
    workingHours: workingHours ?? this.workingHours,
    reminderHours: reminderHours ?? this.reminderHours,
    escalationHours: escalationHours ?? this.escalationHours,
    escalationMaxLevel: escalationMaxLevel ?? this.escalationMaxLevel,
    smsEnabled: smsEnabled ?? this.smsEnabled,
    smsMonthlyCap: smsMonthlyCap ?? this.smsMonthlyCap,
  );

  /// Fields of [edited] that differ from this. Only keys from the rules'
  /// allow-list for organisation updates are ever returned; the caller adds
  /// `updatedAt` (server time).
  Map<String, Object?> changedFields(OrgSettings edited) => {
    if (edited.workingHoursEnabled != workingHoursEnabled)
      'workingHoursEnabled': edited.workingHoursEnabled,
    if (edited.workingHours != workingHours)
      'workingHours': edited.workingHours.toMap(),
    if (!listEqualsOrdered(edited.reminderHours, reminderHours))
      'reminderHours': edited.reminderHours,
    if (edited.escalationHours != escalationHours)
      'escalationHours': edited.escalationHours,
    if (edited.escalationMaxLevel != escalationMaxLevel)
      'escalationMaxLevel': edited.escalationMaxLevel,
    if (edited.smsEnabled != smsEnabled) 'smsEnabled': edited.smsEnabled,
    if (edited.smsMonthlyCap != smsMonthlyCap)
      'smsMonthlyCap': edited.smsMonthlyCap,
  };

  @override
  bool operator ==(Object other) =>
      other is OrgSettings &&
      other.name == name &&
      other.timezone == timezone &&
      changedFields(other).isEmpty;

  @override
  int get hashCode => Object.hash(
    name,
    timezone,
    workingHoursEnabled,
    workingHours,
    Object.hashAll(reminderHours),
    escalationHours,
    escalationMaxLevel,
    smsEnabled,
    smsMonthlyCap,
  );
}

/// Parses "24, 1" into `[24, 1]` (largest first, no duplicates). Returns
/// null if any part is not a whole number between 1 and
/// [OrgSettings.maxHours], or if the list is empty.
List<int>? parseReminderHours(String input) {
  final parts = input
      .split(RegExp(r'[,\s]+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return null;
  final hours = <int>{};
  for (final part in parts) {
    final value = int.tryParse(part);
    if (value == null || value < 1 || value > OrgSettings.maxHours) {
      return null;
    }
    hours.add(value);
  }
  return hours.toList()..sort((a, b) => b.compareTo(a));
}

/// Parses `HH:mm` (24-hour). Returns null when invalid.
({int hour, int minute})? parseClock(String value) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
  if (match == null) return null;
  final hour = int.parse(match[1]!);
  final minute = int.parse(match[2]!);
  if (hour > 23 || minute > 59) return null;
  return (hour: hour, minute: minute);
}

String formatClock(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
