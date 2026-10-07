import 'enum_parsing.dart';

/// Status of a task (spec 4.3). "Overdue" is not a status: it is the
/// separate `overdue` flag set by the server (spec 4.5).
enum TaskStatus {
  todo('todo'),
  inProgress('in_progress'),
  blocked('blocked'),
  done('done'),
  cancelled('cancelled');

  const TaskStatus(this.firestoreValue);

  final String firestoreValue;

  static TaskStatus fromFirestore(Object? raw) =>
      parseEnum(values, raw, (v) => v.firestoreValue, field: 'status');

  bool get isOpen => this != TaskStatus.done && this != TaskStatus.cancelled;

  /// Blocked and Cancelled ask for a reason (spec 4.3).
  bool get requiresReason =>
      this == TaskStatus.blocked || this == TaskStatus.cancelled;
}
