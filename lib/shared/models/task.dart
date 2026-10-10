import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'assignment_state.dart';
import 'completion_mode.dart';
import 'firestore_converters.dart';
import 'task_priority.dart';
import 'task_status.dart';

/// A task: `orgs/{org}/tasks/{id}` (spec 4.3 and 5).
///
/// DOCUMENTED DEVIATIONS from the spec 5 field list (A-01, A-02, D-06 and
/// the rules in spec 4.3): `completionMode`, `completedByIds`,
/// `blockedReason`, `cancelReason`, `needsCheck`, `returnReason`,
/// `assignmentState`, `assignmentError`, `reassignmentNeeded`,
/// `reassignmentReason`, `updatedBy`, `deleted`.
///
/// The app never writes a whole task: creates and updates are built in
/// `features/tasks/data/task_write_maps.dart` with exactly the fields
/// `firestore.rules` allows for each change.
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
    this.updatedBy,
    this.completionMode = CompletionMode.all,
    this.completedByIds = const [],
    this.blockedReason,
    this.cancelReason,
    this.returnReason,
    this.needsCheck = false,
    this.assignmentState = AssignmentState.assigned,
    this.assignmentError,
    this.reassignmentNeeded = false,
    this.reassignmentReason,
    this.deleted = false,
    this.hasPendingWrites = false,
  });

  /// [hasPendingWrites] comes from the snapshot metadata, not the document.
  factory Task.fromMap(
    String id,
    Map<String, Object?> map, {
    bool hasPendingWrites = false,
  }) => Task(
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
    updatedBy: FirestoreConverters.stringOrNull(map['updatedBy']),
    completionMode: map['completionMode'] == null
        ? CompletionMode.all
        : CompletionMode.fromFirestore(map['completionMode']),
    completedByIds: FirestoreConverters.stringList(map['completedByIds']),
    blockedReason: FirestoreConverters.stringOrNull(map['blockedReason']),
    cancelReason: FirestoreConverters.stringOrNull(map['cancelReason']),
    returnReason: FirestoreConverters.stringOrNull(map['returnReason']),
    needsCheck: FirestoreConverters.boolOr(map['needsCheck'], false),
    // Every task the app creates carries the field; a document without it
    // was written by the server, which only writes assigned tasks.
    assignmentState: map['assignmentState'] == null
        ? AssignmentState.assigned
        : AssignmentState.fromFirestore(map['assignmentState']),
    assignmentError: FirestoreConverters.stringOrNull(map['assignmentError']),
    reassignmentNeeded: FirestoreConverters.boolOr(
      map['reassignmentNeeded'],
      false,
    ),
    reassignmentReason: FirestoreConverters.stringOrNull(
      map['reassignmentReason'],
    ),
    deleted: FirestoreConverters.boolOr(map['deleted'], false),
    hasPendingWrites: hasPendingWrites,
  );

  /// Longest title the Security Rules accept (KI-10).
  static const int maxTitleLength = 200;

  /// Longest description the Security Rules accept.
  static const int maxDescriptionLength = 5000;

  /// Longest blocked, cancel or return reason the Security Rules accept.
  static const int maxReasonLength = 1000;

  /// Most assignees the Security Rules and `reassignTask` accept.
  static const int maxAssignees = 50;

  /// Fields only Cloud Functions write (spec 5 and 6). The app never sends
  /// them. (`viewerIds`, `completedByIds` and `assignmentState` are sent
  /// once, on create, with the fixed values the rules demand.)
  static const Set<String> serverOnlyFields = {
    'templateVersion',
    'currentStep',
    'stepDeadline',
    'escalationLevel',
    'overdue',
    'assignmentError',
    'reassignmentNeeded',
    'reassignmentReason',
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
  final String? updatedBy;
  final CompletionMode completionMode;

  /// With several assignees who must all finish: who has finished (A-02).
  final List<String> completedByIds;
  final String? blockedReason;
  final String? cancelReason;

  /// Why the creator returned the work after checking it (D-06).
  final String? returnReason;

  /// The creator checks the work before it is Done (D-06).
  final bool needsCheck;
  final AssignmentState assignmentState;

  /// Error code the server gave when it refused the assignment (A-01).
  final String? assignmentError;

  /// Set by the server when an assignee was deactivated.
  final bool reassignmentNeeded;
  final String? reassignmentReason;
  final bool deleted;

  /// True while a change made on this phone has not reached the server
  /// ("waiting to sync", spec 4.9). Not stored in Firestore.
  final bool hasPendingWrites;

  bool get isWorkflowTask => templateId != null;

  /// Several assignees who must all mark it done (spec 4.3 step 4).
  bool get needsEveryAssignee =>
      assigneeIds.length > 1 && completionMode == CompletionMode.all;

  /// Overdue by the clock, or flagged by the server.
  bool isOverdueAt(DateTime now) =>
      status.isOpen && (overdue || deadline.isBefore(now));

  /// Full document representation (as stored in Firestore). Used for tests
  /// and fakes only; the app writes with `task_write_maps.dart`.
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
    'updatedBy': updatedBy,
    'completionMode': completionMode.firestoreValue,
    'completedByIds': completedByIds,
    'blockedReason': blockedReason,
    'cancelReason': cancelReason,
    'returnReason': returnReason,
    'needsCheck': needsCheck,
    'assignmentState': assignmentState.firestoreValue,
    'assignmentError': assignmentError,
    'reassignmentNeeded': reassignmentNeeded,
    'reassignmentReason': reassignmentReason,
    'deleted': deleted,
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
      other.updatedBy == updatedBy &&
      other.completionMode == completionMode &&
      listEqualsOrdered(other.completedByIds, completedByIds) &&
      other.blockedReason == blockedReason &&
      other.cancelReason == cancelReason &&
      other.returnReason == returnReason &&
      other.needsCheck == needsCheck &&
      other.assignmentState == assignmentState &&
      other.assignmentError == assignmentError &&
      other.reassignmentNeeded == reassignmentNeeded &&
      other.reassignmentReason == reassignmentReason &&
      other.deleted == deleted &&
      other.hasPendingWrites == hasPendingWrites;

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
    updatedBy,
    completionMode,
    Object.hashAll(completedByIds),
    blockedReason,
    cancelReason,
    returnReason,
    needsCheck,
    assignmentState,
    assignmentError,
    reassignmentNeeded,
    reassignmentReason,
    deleted,
    hasPendingWrites,
  ]);

  /// Never includes the title or description (they may be confidential).
  @override
  String toString() =>
      'Task(id: $id, status: ${status.name}, '
      'assignment: ${assignmentState.name}, confidential: $confidential)';
}
