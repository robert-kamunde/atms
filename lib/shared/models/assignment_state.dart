import 'enum_parsing.dart';

/// Whether the server has accepted the people on a new task (A-01,
/// "assigned when online"). The app creates every task as [pending]; the
/// `onTaskCreated` Cloud Function sets [assigned] or [rejected].
enum AssignmentState {
  pending('pending'),
  assigned('assigned'),
  rejected('rejected');

  const AssignmentState(this.firestoreValue);

  final String firestoreValue;

  static AssignmentState fromFirestore(Object? raw) =>
      parseEnum(values, raw, (v) => v.firestoreValue, field: 'assignmentState');
}
