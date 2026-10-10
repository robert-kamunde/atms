import 'package:atms/core/config/firebase_providers.dart';
import 'package:atms/core/services/callable_client.dart';
import 'package:atms/features/auth/presentation/auth_providers.dart';
import 'package:atms/shared/models/models.dart';
import 'package:atms/shared/providers/sync_providers.dart';
import 'package:atms/shared/services/sync_status_source.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'fakes.dart';

/// Overrides for a screen test signed in as [user] over [db], with the sync
/// banner hidden (its own tests drive it).
List<Override> taskScreenOverrides(
  AppUser user,
  FakeFirebaseFirestore db, {
  bool adminVerified = false,
  CallableClient? callables,
}) => [
  signedInSession(
    user,
    adminVerifiedUntil: adminVerified ? DateTime.utc(2100) : null,
  ),
  firestoreProvider.overrideWithValue(db),
  clockProvider.overrideWithValue(() => testNow),
  syncStatusSourceProvider.overrideWithValue(const UnknownSyncStatusSource()),
  if (callables != null) callableClientProvider.overrideWithValue(callables),
];

/// Seeds [people] as users of [testOrg].
Future<void> seedPeople(FakeFirebaseFirestore db, List<AppUser> people) async {
  for (final p in people) {
    await db
        .collection('orgs')
        .doc(testOrg)
        .collection('users')
        .doc(p.id)
        .set(p.toMap());
  }
}

AppUser personFixture(
  String id,
  String name, {
  UserRole role = UserRole.staff,
  List<String> chain = const [],
}) => AppUser(
  id: id,
  orgId: testOrg,
  name: name,
  role: role,
  deptId: 'finance',
  managerChain: chain,
  supervisorId: chain.isEmpty ? null : chain.first,
  consentVersion: 'x',
);

/// A simple assigned task: created by `creator`, assigned to `asha`, due a
/// day after [testNow].
Task taskFixture({
  String id = 't1',
  String title = 'Prepare the monthly report',
  TaskStatus status = TaskStatus.todo,
  TaskPriority priority = TaskPriority.high,
  String creatorId = 'creator',
  List<String> assigneeIds = const ['asha'],
  List<String>? viewerIds,
  CompletionMode completionMode = CompletionMode.all,
  List<String> completedByIds = const [],
  bool needsCheck = false,
  AssignmentState assignmentState = AssignmentState.assigned,
  String? assignmentError,
  DateTime? deadline,
  String deptId = 'finance',
  bool confidential = false,
  String? templateId,
  bool deleted = false,
  bool reassignmentNeeded = false,
  String? blockedReason,
  String? returnReason,
  String description = '',
}) => Task(
  id: id,
  title: title,
  description: description,
  priority: priority,
  status: status,
  deadline: deadline ?? testNow.add(const Duration(days: 1)),
  creatorId: creatorId,
  assigneeIds: assigneeIds,
  viewerIds: viewerIds ?? {creatorId, ...assigneeIds}.toList(),
  deptId: deptId,
  confidential: confidential,
  templateId: templateId,
  completionMode: completionMode,
  completedByIds: completedByIds,
  needsCheck: needsCheck,
  assignmentState: assignmentState,
  assignmentError: assignmentError,
  deleted: deleted,
  reassignmentNeeded: reassignmentNeeded,
  blockedReason: blockedReason,
  returnReason: returnReason,
  createdAt: testNow.subtract(const Duration(days: 1)),
  updatedAt: testNow.subtract(const Duration(days: 1)),
);

Future<void> seedTask(FakeFirebaseFirestore db, Task task) => db
    .collection('orgs')
    .doc(testOrg)
    .collection('tasks')
    .doc(task.id)
    .set(task.toMap());

Future<void> seedAudit(
  FakeFirebaseFirestore db,
  String id,
  Map<String, Object?> data,
) => db.collection('orgs').doc(testOrg).collection('audit').doc(id).set(data);

Future<Map<String, dynamic>> readTask(
  FakeFirebaseFirestore db,
  String id,
) async =>
    (await db.collection('orgs').doc(testOrg).collection('tasks').doc(id).get())
        .data()!;
