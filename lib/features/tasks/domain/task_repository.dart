import 'package:flutter/foundation.dart';

import '../../../shared/models/completion_mode.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/task_priority.dart';
import '../../../shared/models/task_status.dart';
import '../../../shared/services/paginated_query.dart';
import 'task_filter.dart';

/// What the creator enters to create a task, or to send a refused one
/// again (spec 4.3 step 1). Confidential creation is Sprint 5, so the task
/// is never confidential here.
@immutable
class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.deadline,
    required this.priority,
    required this.assigneeIds,
    required this.deptId,
    this.description = '',
    this.completionMode = CompletionMode.all,
    this.needsCheck = false,
  });

  final String title;
  final String description;
  final DateTime deadline;
  final TaskPriority priority;
  final List<String> assigneeIds;

  /// The task's department (the creator's department).
  final String deptId;
  final CompletionMode completionMode;
  final bool needsCheck;
}

/// The plain fields the creator may change on an open task. Null means
/// unchanged: only edited fields are sent (spec 4.9 step 4), so two people
/// editing different fields do not overwrite each other.
@immutable
class TaskEdit {
  const TaskEdit({
    this.title,
    this.description,
    this.priority,
    this.deadline,
    this.needsCheck,
  });

  /// The fields of [after] that differ from [before].
  factory TaskEdit.between(Task before, TaskDraft after) => TaskEdit(
    title: after.title == before.title ? null : after.title,
    description: after.description == before.description
        ? null
        : after.description,
    priority: after.priority == before.priority ? null : after.priority,
    deadline: after.deadline.isAtSameMomentAs(before.deadline)
        ? null
        : after.deadline,
    needsCheck: after.needsCheck == before.needsCheck ? null : after.needsCheck,
  );

  final String? title;
  final String? description;
  final TaskPriority? priority;
  final DateTime? deadline;
  final bool? needsCheck;

  bool get isEmpty =>
      title == null &&
      description == null &&
      priority == null &&
      deadline == null &&
      needsCheck == null;
}

/// Tasks of the organisation. Writes go straight to Firestore with
/// exactly the fields `firestore.rules` allows for each change, so they
/// work offline (queued on the phone). Each write method returns the
/// Firestore future, which completes only when the server confirms;
/// callers use `awaitOfflineCapableWrite`. Every update also sets
/// `updatedAt` (server time), `updatedBy` and `clientUpdatedAt` (phone
/// time, from which the server detects changes made offline).
abstract interface class TaskRepository {
  /// A new document id (known before the write, so the app can open the
  /// task at once, even offline).
  String newTaskId();

  /// Creates a pending task (A-01); the server assigns it when online.
  Future<void> create(String taskId, TaskDraft draft);

  /// The task, live, with "waiting to sync" from the snapshot metadata.
  /// Emits null when it does not exist; a refused read is a
  /// `PermissionDeniedFailure` (shown as "not found", A-17).
  Stream<Task?> watchTask(String taskId);

  /// Task lists are live (PDD AC-4.3-2: status changes show within
  /// seconds) and paged: see [LivePaginatedSource].
  ///
  /// My Tasks: open tasks assigned to me, by deadline.
  LivePaginatedSource<Task> myTasks();

  /// Tasks I created that the server has not assigned yet or refused.
  LivePaginatedSource<Task> myUnassignedTasks();

  /// Team Tasks for managers (and admins without a second factor):
  /// tasks they can see, by deadline. [filter]'s status, priority and due
  /// date become query clauses; the rest is filtered within loaded pages.
  LivePaginatedSource<Task> teamTasks(
    TaskFilter filter, {
    required DateTime now,
  });

  /// Team Tasks for verified admins: every non-confidential task.
  LivePaginatedSource<Task> orgTasks(
    TaskFilter filter, {
    required DateTime now,
  });

  Future<void> updateDetails(String taskId, TaskEdit edit);

  /// An assignee moves the task (start, blocked with a reason, resume,
  /// done or waiting for check).
  Future<void> changeStatus(String taskId, TaskStatus to, {String? reason});

  /// One of several assignees marks their part done (A-02).
  Future<void> markMyPartDone(String taskId);

  /// The creator confirms checked work (Waiting for check -> Done).
  Future<void> confirmCheck(String taskId);

  /// The creator returns checked work with a reason (-> In progress).
  Future<void> returnWork(String taskId, String reason);

  Future<void> cancel(String taskId, String reason);

  /// Soft delete (managers before work starts, verified admins).
  Future<void> softDelete(String taskId);

  /// Sends a refused task again with corrected fields (A-01).
  Future<void> resubmit(String taskId, TaskDraft draft);

  /// Deletes a pending or refused task (creator).
  Future<void> discard(String taskId);

  /// Changes the assignees through the `reassignTask` callable (online
  /// only: offline it fails with `ConnectionRequiredFailure`).
  Future<void> reassign(String taskId, List<String> assigneeIds);
}
