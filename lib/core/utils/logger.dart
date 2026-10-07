import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Severity of a log entry.
enum LogLevel { debug, info, warning, error }

/// A single log record, kept so tests (and later Crashlytics) can inspect it.
@immutable
class LogRecord {
  const LogRecord({
    required this.level,
    required this.message,
    required this.context,
    this.error,
    this.stackTrace,
  });

  final LogLevel level;
  final String message;
  final Map<String, Object?> context;
  final Object? error;
  final StackTrace? stackTrace;
}

/// Debug logger for ATMS.
///
/// Privacy rules (spec 4.8 and 6, Tanzania PDPA 2022):
/// * Never log task titles, descriptions, comment text or other content.
///   Pass identifiers (task id, org id, error code) in [context] instead.
/// * Any [context] key that could hold content is redacted automatically
///   (see [redactedKeys]), as a safety net, not as permission to pass it.
/// * Output only goes to the debug console in debug builds. In release
///   builds nothing is printed. (Crashlytics forwarding: Sprint 6.)
///
/// Errors must never be swallowed: every `catch` either rethrows, maps the
/// error to an `AppFailure` the UI shows, or logs it here.
class AppLogger {
  AppLogger._();

  /// Keys whose values are replaced with `<redacted>` in every record.
  static const Set<String> redactedKeys = {
    'title',
    'tasktitle',
    'description',
    'text',
    'comment',
    'body',
    'name',
    'phone',
    'phonenumber',
    'email',
    'password',
    'code',
    'smscode',
  };

  static const String redactedValue = '<redacted>';

  /// Listeners receive every record (used by tests; later by Crashlytics).
  static final List<void Function(LogRecord record)> _listeners = [];

  static void addListener(void Function(LogRecord record) listener) =>
      _listeners.add(listener);

  static void removeListener(void Function(LogRecord record) listener) =>
      _listeners.remove(listener);

  static void debug(
    String message, {
    Map<String, Object?> context = const {},
  }) => _log(LogLevel.debug, message, context);

  static void info(String message, {Map<String, Object?> context = const {}}) =>
      _log(LogLevel.info, message, context);

  static void warning(
    String message, {
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) => _log(LogLevel.warning, message, context, error, stackTrace);

  static void error(
    String message, {
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) => _log(LogLevel.error, message, context, error, stackTrace);

  /// Returns a copy of [context] with content-bearing keys redacted.
  static Map<String, Object?> redact(Map<String, Object?> context) => {
    for (final entry in context.entries)
      entry.key: redactedKeys.contains(entry.key.toLowerCase())
          ? redactedValue
          : entry.value,
  };

  static void _log(
    LogLevel level,
    String message,
    Map<String, Object?> context, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final record = LogRecord(
      level: level,
      message: message,
      context: redact(context),
      error: error,
      stackTrace: stackTrace,
    );
    for (final listener in List.of(_listeners)) {
      listener(record);
    }
    if (!kDebugMode) return;
    final contextText = record.context.isEmpty ? '' : ' ${record.context}';
    developer.log(
      '[${level.name}] $message$contextText',
      name: 'atms',
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      },
      error: error,
      stackTrace: stackTrace,
    );
  }
}
