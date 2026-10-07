import 'package:cloud_firestore/cloud_firestore.dart';

/// Small helpers shared by the `fromMap`/`toMap` of every model.
abstract final class FirestoreConverters {
  /// Reads a timestamp stored as a Firestore [Timestamp], always as UTC
  /// (screens convert to local time when displaying). A [DateTime] is
  /// also accepted (fake Firestore in tests, cached pending writes).
  static DateTime? dateOrNull(Object? raw) => switch (raw) {
    null => null,
    Timestamp() => raw.toDate().toUtc(),
    DateTime() => raw.toUtc(),
    _ => throw FormatException('Expected a timestamp', raw),
  };

  static DateTime date(Object? raw, {required String field}) =>
      dateOrNull(raw) ?? (throw FormatException('Missing $field'));

  static Timestamp? timestampOrNull(DateTime? value) =>
      value == null ? null : Timestamp.fromDate(value);

  static List<String> stringList(Object? raw) => switch (raw) {
    null => const <String>[],
    List<Object?>() => List.unmodifiable(raw.cast<String>()),
    _ => throw FormatException('Expected a list of strings', raw),
  };

  static String string(Object? raw, {required String field}) => switch (raw) {
    String() => raw,
    _ => throw FormatException('Missing or invalid $field', raw),
  };

  static String? stringOrNull(Object? raw) => raw is String ? raw : null;

  static int intOr(Object? raw, int fallback) =>
      raw is num ? raw.toInt() : fallback;

  static int? intOrNull(Object? raw) => raw is num ? raw.toInt() : null;

  static bool boolOr(Object? raw, bool fallback) =>
      raw is bool ? raw : fallback;
}

/// Order-sensitive list equality for model `==`.
bool listEqualsOrdered<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
