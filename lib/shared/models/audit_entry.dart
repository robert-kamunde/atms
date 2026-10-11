import 'package:flutter/foundation.dart';

import 'firestore_converters.dart';

/// What an audit entry records (docs/SPRINT2_CONTRACT.md, "Audit").
enum AuditAction {
  taskCreated('task_created'),
  taskAssigned('task_assigned'),
  taskRejected('task_rejected'),
  taskReassigned('task_reassigned'),
  statusChanged('status_changed'),
  deadlineChanged('deadline_changed'),
  taskEdited('task_edited'),
  taskCancelled('task_cancelled'),
  taskDeleted('task_deleted'),
  taskCompletedBy('task_completed_by'),
  checkReturned('check_returned'),
  userAdded('user_added'),
  userUpdated('user_updated'),
  userDeactivated('user_deactivated'),

  /// An action this version of the app does not know yet (later sprints
  /// add workflow and comment actions). Shown as a generic change.
  other('other');

  const AuditAction(this.firestoreValue);

  final String firestoreValue;

  /// Never throws: unknown actions become [other], so a newer server never
  /// breaks the activity log of an older app.
  static AuditAction parse(Object? raw) {
    for (final action in values) {
      if (action.firestoreValue == raw) return action;
    }
    return AuditAction.other;
  }
}

/// `orgs/{org}/audit/{id}` (spec 4.11). Written only by Cloud Functions;
/// the app only reads it.
@immutable
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.action,
    required this.actorId,
    this.taskId,
    this.before = const {},
    this.after = const {},
    this.at,
    this.madeOffline = false,
    this.confidential = false,
  });

  factory AuditEntry.fromMap(String id, Map<String, Object?> map) => AuditEntry(
    id: id,
    action: AuditAction.parse(map['action']),
    actorId: FirestoreConverters.stringOrNull(map['actorId']) ?? '',
    taskId: FirestoreConverters.stringOrNull(map['taskId']),
    before: _fields(map['before']),
    after: _fields(map['after']),
    at: FirestoreConverters.dateOrNull(map['at']),
    madeOffline: FirestoreConverters.boolOr(map['madeOffline'], false),
    confidential: FirestoreConverters.boolOr(map['confidential'], false),
  );

  static Map<String, Object?> _fields(Object? raw) => raw is Map
      ? Map<String, Object?>.unmodifiable(raw.cast<String, Object?>())
      : const {};

  final String id;
  final AuditAction action;

  /// Who did it. Empty for actions of the system itself.
  final String actorId;

  /// Null for user actions (`user_added`, ...).
  final String? taskId;

  /// Only the changed fields, before and after.
  final Map<String, Object?> before;
  final Map<String, Object?> after;

  /// Server time of the action.
  final DateTime? at;

  /// True when the change was made on a phone without a connection and
  /// synced more than 60 seconds later.
  final bool madeOffline;
  final bool confidential;

  /// Never includes before/after values (they may be confidential).
  @override
  String toString() => 'AuditEntry(id: $id, action: ${action.firestoreValue})';
}
