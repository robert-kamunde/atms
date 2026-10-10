import 'package:flutter/foundation.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/models/assignment_state.dart';
import '../../../shared/models/completion_mode.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/task_status.dart';
import '../../../shared/models/user_role.dart';

/// The person acting on a task, as far as the app knows.
@immutable
class TaskActor {
  const TaskActor({
    required this.uid,
    required this.role,
    this.isVerifiedAdmin = false,
  });

  final String uid;
  final UserRole role;

  /// Admin with a current second factor (D-01). Admin powers need it.
  final bool isVerifiedAdmin;

  bool get isManager => role == UserRole.manager;
}

/// Every task action the app offers (spec 4.3, D-06, A-01).
enum TaskAction {
  start,
  block,
  resume,

  /// Done, or "Send for check" when the creator asked to check (D-06).
  markDone,

  /// One of several assignees who must all finish marks their part (A-02).
  markMyPartDone,
  confirmCheck,
  returnWork,
  cancel,
  edit,
  reassign,
  delete,

  /// The creator fixes a refused assignment and sends it again (A-01).
  resubmit,

  /// The creator deletes a task that is still pending or was refused.
  discard,
}

/// Which actions the app offers to whom. It mirrors the task section of
/// `firestore.rules` and the Sprint 2 contract so the app never offers a
/// change the server refuses. It is NOT a security check: the rules and
/// Cloud Functions decide (spec 6). Keep in step with the rules.
abstract final class TaskPolicy {
  /// Actions [actor] may take on [task] now.
  static Set<TaskAction> allowedActions(Task task, TaskActor actor) => {
    for (final action in TaskAction.values)
      if (can(action, task, actor)) action,
  };

  static bool can(TaskAction action, Task task, TaskActor actor) {
    if (task.deleted) return false;
    final isCreator = task.creatorId == actor.uid;
    final isAssignee = task.assigneeIds.contains(actor.uid);
    // Workflow tasks move through transition requests (Sprint 3).
    if (task.isWorkflowTask) {
      return action == TaskAction.edit && _creatorEdit(task, isCreator) ||
          action == TaskAction.delete && _softDelete(task, actor, isCreator);
    }
    switch (action) {
      case TaskAction.resubmit:
        return isCreator && task.assignmentState == AssignmentState.rejected;
      case TaskAction.discard:
        return isCreator && task.assignmentState != AssignmentState.assigned;
      case _:
        break;
    }
    // Every other update needs a task the server has assigned.
    if (task.assignmentState != AssignmentState.assigned) return false;
    final status = task.status;
    return switch (action) {
      TaskAction.start => isAssignee && status == TaskStatus.todo,
      TaskAction.block => isAssignee && status == TaskStatus.inProgress,
      TaskAction.resume => isAssignee && status == TaskStatus.blocked,
      TaskAction.markDone =>
        isAssignee &&
            (status == TaskStatus.todo || status == TaskStatus.inProgress) &&
            (task.assigneeIds.length == 1 ||
                task.completionMode == CompletionMode.any),
      TaskAction.markMyPartDone =>
        isAssignee &&
            status.isActive &&
            task.needsEveryAssignee &&
            !task.completedByIds.contains(actor.uid),
      TaskAction.confirmCheck ||
      TaskAction.returnWork => isCreator && status == TaskStatus.awaitingCheck,
      TaskAction.cancel => status.isActive && (isCreator || actor.isManager),
      TaskAction.edit => _creatorEdit(task, isCreator),
      // The server checks the reporting tree; the app offers it to the
      // people who can be allowed (contract, `reassignTask`).
      TaskAction.reassign =>
        status.isActive &&
            (isCreator ||
                actor.isManager ||
                (actor.isVerifiedAdmin && !task.confidential)),
      TaskAction.delete => _softDelete(task, actor, isCreator),
      TaskAction.resubmit || TaskAction.discard => false,
    };
  }

  static bool _creatorEdit(Task task, bool isCreator) =>
      isCreator &&
      task.assignmentState == AssignmentState.assigned &&
      task.status.isActive;

  static bool _softDelete(Task task, TaskActor actor, bool isCreator) =>
      task.assignmentState == AssignmentState.assigned &&
      (actor.isVerifiedAdmin ||
          (actor.isManager && isCreator && task.status == TaskStatus.todo));

  /// The status an assignee's "Done" writes: Done, or Waiting for check
  /// when the creator asked to check the work (D-06).
  static TaskStatus doneTarget(Task task) =>
      task.needsCheck ? TaskStatus.awaitingCheck : TaskStatus.done;

  /// Only reassign needs a connection; every other action works offline
  /// (spec 4.9).
  static bool needsConnection(TaskAction action) =>
      action == TaskAction.reassign;
}

/// Who the app offers as assignees (spec 2 matrix, contract "Task
/// creation"). The server checks again and refuses anyone else.
enum AssigneeScope {
  /// Staff, and admins without a current second factor: only themselves.
  selfOnly,

  /// Managers: themselves and everyone with them in `managerChain`.
  team,

  /// Verified admins: anyone in the organisation.
  anyone,
}

AssigneeScope assigneeScopeFor(TaskActor actor) => switch (actor.role) {
  UserRole.staff => AssigneeScope.selfOnly,
  UserRole.manager => AssigneeScope.team,
  UserRole.admin =>
    actor.isVerifiedAdmin ? AssigneeScope.anyone : AssigneeScope.selfOnly,
};

/// True when [actor] may be offered [person] as an assignee.
bool canOfferAssignee(TaskActor actor, AppUser person) {
  if (!person.active) return false;
  if (person.id == actor.uid) return true;
  return switch (assigneeScopeFor(actor)) {
    AssigneeScope.selfOnly => false,
    AssigneeScope.team => person.managerChain.contains(actor.uid),
    AssigneeScope.anyone => true,
  };
}
