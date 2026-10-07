import 'package:flutter/foundation.dart';

import '../../../shared/models/task_priority.dart';
import '../../../shared/models/task_status.dart';

/// Due-date filter options (spec 4.3: "Filters work by ... due date").
enum DueFilter { today, thisWeek, overdue }

/// Filters for task lists. Applied as Firestore query clauses in Sprint 2
/// (indexes: viewerIds + status + deadline; spec 5).
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
}
