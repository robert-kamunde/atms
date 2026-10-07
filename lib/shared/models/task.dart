import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'completion_mode.dart';
import 'firestore_converters.dart';
import 'task_priority.dart';
import 'task_status.dart';

/// A task: `orgs/{org}/tasks/{id}` (spec 4.3 and 5).
///
/// DOCUMENTED DEVIATIONS from the spec 5 field list (all needed by rules in
/// spec 4.3): `completionMode`, `completedByIds`, `blockedReason`,
/// `cancelReason`.
@immutable
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    required this.deadline,
    required this.creatorId,
    required this.assigneeIds,
    required this.deptId,
    this.description = '',
    this.confidential = false,
    this.participantIds = const [],
    this.viewerIds = const [],
    this.templateId,
    this.templateVersion,
    this.currentStep,
    this.stepDeadline,
    this.escalationLevel = 0,
    this.overdue = false,
    this.createdAt,
    this.updatedAt,
    this.completionMode = CompletionMode.all,
    this.completedByIds = const [],
    this.blockedReason,
    this.cancelReason,
  });

  factory Task.fromMap(String id, Map<String, Object?> map) => Task(
    id: id,
    title: FirestoreConverters.string(map['title'], field: 'title'),
    description: FirestoreConverters.stringOrNull(map['description']) ?? '',
    priority: TaskPriority.fromFirestore(map['priority']),
    status: TaskStatus.fromFirestore(map['status']),
    deadline: FirestoreConverters.date(map['deadline'], field: 'deadline'),
    creatorId: FirestoreConverters.string(map['creatorId'], field: 'creatorId'),
    assigneeIds: FirestoreConverters.stringList(map['assigneeIds']),
    deptId: FirestoreConverters.string(map['deptId'], field: 'deptId'),
    confidential: FirestoreConverters.boolOr(map['confidential'], false),
    participantIds: FirestoreConverters.stringList(map['participantIds']),
    viewerIds: FirestoreConverters.stringList(map['viewerIds']),
    templateId: FirestoreConverters.stringOrNull(map['templateId']),
    templateVersion: FirestoreConverters.intOrNull(map['templateVersion']),
    currentStep: FirestoreConverters.intOrNull(map['currentStep']),
    stepDeadline: FirestoreConverters.dateOrNull(map['stepDeadline']),
    escalationLevel: FirestoreConverters.intOr(map['escalationLevel'], 0),
    overdue: FirestoreConverters.boolOr(map['overdue'], false),
    createdAt: FirestoreConverters.dateOrNull(map['createdAt']),
    updatedAt: FirestoreConverters.dateOrNull(map['updatedAt']),
    completionMode: map['completionMode'] == null
        ? CompletionMode.all
        : CompletionMode.fromFirestore(map['completionMode']),
    completedByIds: FirestoreConverters.stringList(map['completedByIds']),
    blockedReason: FirestoreConverters.stringOrNull(map['blockedReason']),
    cancelReason: FirestoreConverters.stringOrNull(map['cancelReason']),
  );

  /// Fields only Cloud Functions may write (spec 5 and 6). The client never
  /// serializes these in a create; Security Rules reject them anyway.
  static const Set<String> serverOnlyFields = {
    'viewerIds',
    'templateVersion',
    'currentStep',
    'stepDeadline',
    'escalationLevel',
    'overdue',
    'completedByIds',
  };

  /// Fields a client may send when creating a simple (non-workflow) task.
  /// Workflow tasks are started through a server request (Sprint 3).
  static const Set<String> clientCreateFields = {
    'title',
    'description',
    'priority',
    'status',
    'deadline',
    'creatorId',
    'assigneeIds',
    'deptId',
    'confidential',
    'participantIds',
    'completionMode',
    'createdAt',
    'updatedAt',
  };

  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime deadline;
  final String creatorId;
  final List<String> assigneeIds;
  final String deptId;
  final bool confidential;

  /// For confidential tasks: the only people who may see it (spec 4.8).
  final List<String> participantIds;

  /// Filled by the server with everyone allowed to read the task.
  final List<String> viewerIds;

  final String? templateId;
  final int? templateVersion;

  /// Index of the current workflow step. Server only.
  final int? currentStep;
  final DateTime? stepDeadline;
  final int escalationLevel;
  final bool overdue;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CompletionMode completionMode;
  final List<String> completedByIds;
  final String? blockedReason;
  final String? cancelReason;

  bool get isWorkflowTask => templateId != null;

  /// Full document representation (as stored in Firestore). Used for
  /// round-trip tests and by trusted code paths only; the app uses
  /// [toClientCreateMap] when writing.
  Map<String, Object?> toMap() => {
    'title': title,
    'description': description,
    'priority': priority.firestoreValue,
    'status': status.firestoreValue,
    'deadline': Timestamp.fromDate(deadline),
    'creatorId': creatorId,
    'assigneeIds': assigneeIds,
    'deptId': deptId,
    'confidential': confidential,
    'participantIds': participantIds,
    'viewerIds': viewerIds,
    'templateId': templateId,
    'templateVersion': templateVersion,
    'currentStep': currentStep,
    'stepDeadline': FirestoreConverters.timestampOrNull(stepDeadline),
    'escalationLevel': escalationLevel,
    'overdue': overdue,
    'createdAt': FirestoreConverters.timestampOrNull(createdAt),
    'updatedAt': FirestoreConverters.timestampOrNull(updatedAt),
    'completionMode': completionMode.firestoreValue,
    'completedByIds': completedByIds,
    'blockedReason': blockedReason,
    'cancelReason': cancelReason,
  };

  /// The map a client sends to create a new simple task.
  ///
  /// Contains only [clientCreateFields]. Status is always `todo` (spec 4.3:
  /// "Creator, on creation"). Timestamps use the server clock.
  Map<String, Object?> toClientCreateMap() => {
    'title': title,
    'description': description,
    'priority': priority.firestoreValue,
    'status': TaskStatus.todo.firestoreValue,
    'deadline': Timestamp.fromDate(deadline),
    'creatorId': creatorId,
    'assigneeIds': assigneeIds,
    'deptId': deptId,
    'confidential': confidential,
    'participantIds': confidential ? participantIds : const <String>[],
    'completionMode': completionMode.firestoreValue,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  @override
  bool operator ==(Object other) =>
      other is Task &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.priority == priority &&
      other.status == status &&
      other.deadline == deadline &&
      other.creatorId == creatorId &&
      listEqualsOrdered(other.assigneeIds, assigneeIds) &&
      other.deptId == deptId &&
      other.confidential == confidential &&
      listEqualsOrdered(other.participantIds, participantIds) &&
      listEqualsOrdered(other.viewerIds, viewerIds) &&
      other.templateId == templateId &&
      other.templateVersion == templateVersion &&
      other.currentStep == currentStep &&
      other.stepDeadline == stepDeadline &&
      other.escalationLevel == escalationLevel &&
      other.overdue == overdue &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.completionMode == completionMode &&
      listEqualsOrdered(other.completedByIds, completedByIds) &&
      other.blockedReason == blockedReason &&
      other.cancelReason == cancelReason;

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    description,
    priority,
    status,
    deadline,
    creatorId,
    Object.hashAll(assigneeIds),
    deptId,
    confidential,
    Object.hashAll(participantIds),
    Object.hashAll(viewerIds),
    templateId,
    templateVersion,
    currentStep,
    stepDeadline,
    escalationLevel,
    overdue,
    createdAt,
    updatedAt,
    completionMode,
    Object.hashAll(completedByIds),
    blockedReason,
    cancelReason,
  ]);

  /// Never includes the title or description (they may be confidential).
  @override
  String toString() =>
      'Task(id: $id, status: ${status.name}, confidential: $confidential)';
}
