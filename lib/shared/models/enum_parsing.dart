/// Helper for enums stored in Firestore as strings.
///
/// Each model enum exposes a `firestoreValue` (the exact string stored in
/// Firestore) and a `fromFirestore` factory built on [parseEnum].
T parseEnum<T extends Enum>(
  List<T> values,
  Object? raw,
  String Function(T value) toFirestore, {
  required String field,
}) {
  for (final value in values) {
    if (toFirestore(value) == raw) return value;
  }
  throw FormatException('Unknown value for $field', raw);
}
