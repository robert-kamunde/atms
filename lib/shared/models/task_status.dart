import 'enum_parsing.dart';

/// Status of a task (spec 4.3, D-06). "Overdue" is not a status: it is the
/// separate `overdue` flag set by the server (spec 4.5).
///
/// DOCUMENTED DEVIATION (D-06): [awaitingCheck] ("Waiting for check") is
/// added for tasks whose creator asked to check the work (`needsCheck`).
enum TaskStatus {
  todo('todo'),
  inProgress('in_progress'),
  blocked('blocked'),
  awaitingCheck('awaiting_check'),
  done('done'),
  cancelled('cancelled');

  const TaskStatus(this.firestoreValue);

  final String firestoreValue;

  static TaskStatus fromFirestore(Object? raw) =>
      parseEnum(values, raw, (v) => v.firestoreValue, field: 'status');

  /// Not finished: everything except Done and Cancelled.
  bool get isOpen => this != TaskStatus.done && this != TaskStatus.cancelled;

  /// The statuses `firestore.rules` calls open (`isOpen()`): the work can
  /// still change, be edited or be cancelled. Waiting for check is not one.
  bool get isActive =>
      this == TaskStatus.todo ||
      this == TaskStatus.inProgress ||
      this == TaskStatus.blocked;

  /// Blocked and Cancelled ask for a reason (spec 4.3).
  bool get requiresReason =>
      this == TaskStatus.blocked || this == TaskStatus.cancelled;

  /// The statuses shown in My Tasks (everything not finished).
  static const List<TaskStatus> openStatuses = [
    TaskStatus.todo,
    TaskStatus.inProgress,
    TaskStatus.blocked,
    TaskStatus.awaitingCheck,
  ];
}
