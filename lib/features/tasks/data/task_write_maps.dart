import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/assignment_state.dart';
import '../../../shared/models/task_status.dart';
import '../domain/task_repository.dart';

/// Builds the exact maps the app writes to `orgs/{org}/tasks/{id}`.
///
/// Each map contains only the fields `firestore.rules` (task section) and
/// docs/SPRINT2_CONTRACT.md allow for that change; anything more and the
/// server refuses the write. Unit tests pin every field set.
class TaskWriteMaps {
  const TaskWriteMaps({required this.uid, required this.clientNow});

  /// The signed-in person (`updatedBy`, `creatorId`).
  final String uid;

  /// The phone's clock (`clientUpdatedAt`; the server compares it with its
  /// own time to mark changes made offline).
  final DateTime clientNow;

  /// Bookkeeping fields every update carries (rules: `bookkeeping()`).
  Map<String, Object?> get bookkeeping => {
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': uid,
    'clientUpdatedAt': Timestamp.fromDate(clientNow),
  };

  /// A new pending task (A-01): only the creator can see it until the
  /// server assigns it. Never confidential in Sprint 2 (Sprint 5).
  Map<String, Object?> create(TaskDraft draft) => {
    'title': draft.title.trim(),
    'description': draft.description.trim(),
    'priority': draft.priority.firestoreValue,
    'deadline': Timestamp.fromDate(draft.deadline),
    'assigneeIds': List<String>.of(draft.assigneeIds),
    'deptId': draft.deptId,
    'confidential': false,
    'participantIds': const <String>[],
    'completionMode': draft.completionMode.firestoreValue,
    'needsCheck': draft.needsCheck,
    'creatorId': uid,
    'status': TaskStatus.todo.firestoreValue,
    'viewerIds': [uid],
    'assignmentState': AssignmentState.pending.firestoreValue,
    'completedByIds': const <String>[],
    'deleted': false,
    'createdAt': FieldValue.serverTimestamp(),
    ...bookkeeping,
  };

  /// Creator edit of an open task: only the changed plain fields.
  Map<String, Object?> edit(TaskEdit edit) => {
    if (edit.title != null) 'title': edit.title!.trim(),
    if (edit.description != null) 'description': edit.description!.trim(),
    if (edit.priority != null) 'priority': edit.priority!.firestoreValue,
    if (edit.deadline != null) 'deadline': Timestamp.fromDate(edit.deadline!),
    if (edit.needsCheck != null) 'needsCheck': edit.needsCheck,
    ...bookkeeping,
  };

  /// Assignee status change. Blocked carries `blockedReason`.
  Map<String, Object?> status(TaskStatus to, {String? reason}) => {
    'status': to.firestoreValue,
    if (to == TaskStatus.blocked) 'blockedReason': reason!.trim(),
    ...bookkeeping,
  };

  /// One assignee adds only themselves to `completedByIds` (A-02).
  Map<String, Object?> completeMyPart() => {
    'completedByIds': FieldValue.arrayUnion([uid]),
    ...bookkeeping,
  };

  /// Creator confirms checked work (D-06).
  Map<String, Object?> confirmCheck() => {
    'status': TaskStatus.done.firestoreValue,
    ...bookkeeping,
  };

  /// Creator returns checked work with a reason (D-06).
  Map<String, Object?> returnWork(String reason) => {
    'status': TaskStatus.inProgress.firestoreValue,
    'returnReason': reason.trim(),
    ...bookkeeping,
  };

  Map<String, Object?> cancel(String reason) => {
    'status': TaskStatus.cancelled.firestoreValue,
    'cancelReason': reason.trim(),
    ...bookkeeping,
  };

  /// Soft delete (and discarding a pending or refused task).
  Map<String, Object?> softDelete() => {
    'deleted': true,
    'deletedAt': FieldValue.serverTimestamp(),
    ...bookkeeping,
  };

  /// A refused task sent again: corrected fields, back to pending, the
  /// server's error removed.
  Map<String, Object?> resubmit(TaskDraft draft) => {
    'title': draft.title.trim(),
    'description': draft.description.trim(),
    'priority': draft.priority.firestoreValue,
    'deadline': Timestamp.fromDate(draft.deadline),
    'assigneeIds': List<String>.of(draft.assigneeIds),
    'completionMode': draft.completionMode.firestoreValue,
    'needsCheck': draft.needsCheck,
    'assignmentState': AssignmentState.pending.firestoreValue,
    'assignmentError': FieldValue.delete(),
    ...bookkeeping,
  };
}
