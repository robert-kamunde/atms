import 'package:flutter/foundation.dart';

import '../../../shared/models/task.dart';
import '../../../shared/models/task_priority.dart';
import '../../../shared/models/task_status.dart';

/// Due-date filter options (spec 4.3: "Filters work by ... due date").
enum DueFilter { today, thisWeek, overdue }

/// A deadline range: [start] inclusive, [end] exclusive; either may be
/// open.
@immutable
class DeadlineRange {
  const DeadlineRange({this.start, this.end});

  final DateTime? start;
  final DateTime? end;

  bool contains(DateTime deadline) =>
      (start == null || !deadline.isBefore(start!)) &&
      (end == null || deadline.isBefore(end!));
}

/// The deadline range of [due] at [now], in the phone's local days.
/// "This week" runs from now until the end of Sunday.
DeadlineRange deadlineRangeFor(DueFilter due, DateTime now) {
  final local = now.toLocal();
  final startOfToday = DateTime(local.year, local.month, local.day);
  final startOfTomorrow = DateTime(local.year, local.month, local.day + 1);
  return switch (due) {
    DueFilter.today => DeadlineRange(start: startOfToday, end: startOfTomorrow),
    DueFilter.thisWeek => DeadlineRange(
      start: startOfToday,
      end: DateTime(
        local.year,
        local.month,
        local.day + (DateTime.daysPerWeek - local.weekday) + 1,
      ),
    ),
    DueFilter.overdue => DeadlineRange(end: now),
  };
}

/// Filters for task lists (spec 4.3).
///
/// Status, priority, department and due date are selective and indexed,
/// so the Team Tasks query applies them on the server
/// (firestore.indexes.json). The assignee is applied within the loaded
/// pages only (Firestore allows one `array-contains` per query, and the
/// visibility clause already uses it), and the screen says so.
@immutable
class TaskFilter {
  const TaskFilter({
    this.status,
    this.priority,
    this.assigneeId,
    this.deptId,
    this.due,
  });

  final TaskStatus? status;
  final TaskPriority? priority;
  final String? assigneeId;
  final String? deptId;
  final DueFilter? due;

  bool get isEmpty =>
      status == null &&
      priority == null &&
      assigneeId == null &&
      deptId == null &&
      due == null;

  /// True when some filter is applied only within the loaded pages.
  bool get hasPageFilters => assigneeId != null;

  /// The part of the filter the server query applies.
  TaskFilter get queryPart =>
      TaskFilter(status: status, priority: priority, deptId: deptId, due: due);

  /// Does [task] pass every filter at [now]? Used for the filters applied
  /// within loaded pages, and for lists whose query has no filters.
  bool matches(Task task, DateTime now) {
    if (status != null && task.status != status) return false;
    if (priority != null && task.priority != priority) return false;
    if (assigneeId != null && !task.assigneeIds.contains(assigneeId)) {
      return false;
    }
    if (deptId != null && task.deptId != deptId) return false;
    if (due case final due?) {
      if (due == DueFilter.overdue) {
        if (!task.isOverdueAt(now)) return false;
      } else if (!deadlineRangeFor(due, now).contains(task.deadline)) {
        return false;
      }
    }
    return true;
  }

  TaskFilter copyWith({
    ValueGetter<TaskStatus?>? status,
    ValueGetter<TaskPriority?>? priority,
    ValueGetter<String?>? assigneeId,
    ValueGetter<String?>? deptId,
    ValueGetter<DueFilter?>? due,
  }) => TaskFilter(
    status: status != null ? status() : this.status,
    priority: priority != null ? priority() : this.priority,
    assigneeId: assigneeId != null ? assigneeId() : this.assigneeId,
    deptId: deptId != null ? deptId() : this.deptId,
    due: due != null ? due() : this.due,
  );

  @override
  bool operator ==(Object other) =>
      other is TaskFilter &&
      other.status == status &&
      other.priority == priority &&
      other.assigneeId == assigneeId &&
      other.deptId == deptId &&
      other.due == due;

  @override
  int get hashCode => Object.hash(status, priority, assigneeId, deptId, due);
}
