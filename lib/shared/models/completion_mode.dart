import 'enum_parsing.dart';

/// How a task with several assignees is completed (spec 4.3 step 4).
///
/// DOCUMENTED DEVIATION: not listed in the spec 5 data model; added so the
/// "all of them / any one person" rule has somewhere to live.
enum CompletionMode {
  all('all'),
  any('any');

  const CompletionMode(this.firestoreValue);

  final String firestoreValue;

  static CompletionMode fromFirestore(Object? raw) =>
      parseEnum(values, raw, (v) => v.firestoreValue, field: 'completionMode');
}
