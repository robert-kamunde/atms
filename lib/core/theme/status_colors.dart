import 'package:flutter/material.dart';

import '../../shared/models/task_priority.dart';
import '../../shared/models/task_status.dart';

/// Colour tokens for task status and priority.
///
/// Colours are never the only signal: screens always show the localized
/// status/priority label next to the colour (colour-blind users, glare on
/// cheap screens outdoors).
@immutable
class AtmsColors extends ThemeExtension<AtmsColors> {
  const AtmsColors({
    required this.todo,
    required this.inProgress,
    required this.blocked,
    required this.done,
    required this.cancelled,
    required this.overdue,
    required this.priorityLow,
    required this.priorityMedium,
    required this.priorityHigh,
    required this.priorityUrgent,
    required this.offline,
    required this.syncing,
    required this.synced,
  });

  /// High-contrast tokens for the light theme. Each passes WCAG AA (4.5:1)
  /// as text on white and as background behind white text.
  static const light = AtmsColors(
    todo: Color(0xFF455A64), // blue grey 700
    inProgress: Color(0xFF1565C0), // blue 800
    blocked: Color(0xFF8D4B00), // dark amber
    done: Color(0xFF2E7D32), // green 800
    cancelled: Color(0xFF616161), // grey 700
    overdue: Color(0xFFC62828), // red 800
    priorityLow: Color(0xFF546E7A),
    priorityMedium: Color(0xFF1565C0),
    priorityHigh: Color(0xFFB45309),
    priorityUrgent: Color(0xFFC62828),
    offline: Color(0xFF5D4037),
    syncing: Color(0xFF1565C0),
    synced: Color(0xFF2E7D32),
  );

  /// Lighter tones for the dark theme (used as text/icons on dark surfaces).
  static const dark = AtmsColors(
    todo: Color(0xFFB0BEC5),
    inProgress: Color(0xFF90CAF9),
    blocked: Color(0xFFFFCC80),
    done: Color(0xFFA5D6A7),
    cancelled: Color(0xFFBDBDBD),
    overdue: Color(0xFFEF9A9A),
    priorityLow: Color(0xFFB0BEC5),
    priorityMedium: Color(0xFF90CAF9),
    priorityHigh: Color(0xFFFFCC80),
    priorityUrgent: Color(0xFFEF9A9A),
    offline: Color(0xFFBCAAA4),
    syncing: Color(0xFF90CAF9),
    synced: Color(0xFFA5D6A7),
  );

  final Color todo;
  final Color inProgress;
  final Color blocked;
  final Color done;
  final Color cancelled;

  /// Overdue is shown in red on top of the status (spec 4.5).
  final Color overdue;

  final Color priorityLow;
  final Color priorityMedium;
  final Color priorityHigh;
  final Color priorityUrgent;

  final Color offline;
  final Color syncing;
  final Color synced;

  Color forStatus(TaskStatus status) => switch (status) {
    TaskStatus.todo => todo,
    TaskStatus.inProgress => inProgress,
    TaskStatus.blocked => blocked,
    TaskStatus.done => done,
    TaskStatus.cancelled => cancelled,
  };

  Color forPriority(TaskPriority priority) => switch (priority) {
    TaskPriority.low => priorityLow,
    TaskPriority.medium => priorityMedium,
    TaskPriority.high => priorityHigh,
    TaskPriority.urgent => priorityUrgent,
  };

  @override
  AtmsColors copyWith({
    Color? todo,
    Color? inProgress,
    Color? blocked,
    Color? done,
    Color? cancelled,
    Color? overdue,
    Color? priorityLow,
    Color? priorityMedium,
    Color? priorityHigh,
    Color? priorityUrgent,
    Color? offline,
    Color? syncing,
    Color? synced,
  }) => AtmsColors(
    todo: todo ?? this.todo,
    inProgress: inProgress ?? this.inProgress,
    blocked: blocked ?? this.blocked,
    done: done ?? this.done,
    cancelled: cancelled ?? this.cancelled,
    overdue: overdue ?? this.overdue,
    priorityLow: priorityLow ?? this.priorityLow,
    priorityMedium: priorityMedium ?? this.priorityMedium,
    priorityHigh: priorityHigh ?? this.priorityHigh,
    priorityUrgent: priorityUrgent ?? this.priorityUrgent,
    offline: offline ?? this.offline,
    syncing: syncing ?? this.syncing,
    synced: synced ?? this.synced,
  );

  @override
  AtmsColors lerp(ThemeExtension<AtmsColors>? other, double t) {
    if (other is! AtmsColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AtmsColors(
      todo: l(todo, other.todo),
      inProgress: l(inProgress, other.inProgress),
      blocked: l(blocked, other.blocked),
      done: l(done, other.done),
      cancelled: l(cancelled, other.cancelled),
      overdue: l(overdue, other.overdue),
      priorityLow: l(priorityLow, other.priorityLow),
      priorityMedium: l(priorityMedium, other.priorityMedium),
      priorityHigh: l(priorityHigh, other.priorityHigh),
      priorityUrgent: l(priorityUrgent, other.priorityUrgent),
      offline: l(offline, other.offline),
      syncing: l(syncing, other.syncing),
      synced: l(synced, other.synced),
    );
  }
}

extension AtmsColorsX on BuildContext {
  /// The ATMS colour tokens of the current theme.
  AtmsColors get atmsColors =>
      Theme.of(this).extension<AtmsColors>() ?? AtmsColors.light;
}
