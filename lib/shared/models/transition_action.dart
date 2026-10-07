import 'enum_parsing.dart';

/// Actions a user can *request* on a workflow step. Only a Cloud Function
/// applies them (spec 4.4, "Why the server does the moving").
enum TransitionAction {
  submit('submit'),
  approve('approve'),
  reject('reject'),
  sendBack('sendBack');

  const TransitionAction(this.firestoreValue);

  final String firestoreValue;

  static TransitionAction fromFirestore(Object? raw) =>
      parseEnum(values, raw, (v) => v.firestoreValue, field: 'action');

  /// Reject and Send back require a comment (spec 4.4 step 5).
  bool get requiresComment =>
      this == TransitionAction.reject || this == TransitionAction.sendBack;
}
