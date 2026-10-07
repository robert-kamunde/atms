import 'enum_parsing.dart';

/// Who does a workflow step (spec 4.4): a named person, a role, or the
/// previous person's supervisor.
enum StepOwnerType {
  user('user'),
  role('role'),
  supervisor('supervisor');

  const StepOwnerType(this.firestoreValue);

  final String firestoreValue;

  static StepOwnerType fromFirestore(Object? raw) =>
      parseEnum(values, raw, (v) => v.firestoreValue, field: 'ownerType');
}
