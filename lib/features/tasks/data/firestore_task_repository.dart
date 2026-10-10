import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failure_mapper.dart';
import '../../../core/services/callable_client.dart';
import '../../../shared/models/assignment_state.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/task_status.dart';
import '../../../shared/services/paginated_query.dart';
import '../domain/task_filter.dart';
import '../domain/task_repository.dart';
import 'task_write_maps.dart';

/// [TaskRepository] over `orgs/{org}/tasks` and the `reassignTask`
/// callable. Every query matches an index in `firestore.indexes.json` and
/// carries the clauses the read rule needs (`deleted == false` plus
/// `viewerIds array-contains me`, the assignee branch, or the admin
/// branch's `confidential == false`).
class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository(
    this._db,
    this._callables, {
    required this.orgId,
    required this.uid,
    required this.clock,
  });

  final FirebaseFirestore _db;

  /// Read only when a callable is used, so lists and writes never need
  /// Cloud Functions to be set up.
  final CallableClient Function() _callables;
  final String orgId;
  final String uid;

  /// The phone's clock (for `clientUpdatedAt`).
  final DateTime Function() clock;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _db.collection('orgs').doc(orgId).collection('tasks');

  TaskWriteMaps get _maps => TaskWriteMaps(uid: uid, clientNow: clock());

  static Task _decode(String id, Map<String, Object?> data) =>
      Task.fromMap(id, data);

  static Task _decodePending(
    String id,
    Map<String, Object?> data,
    bool hasPendingWrites,
  ) => Task.fromMap(id, data, hasPendingWrites: hasPendingWrites);

  LivePaginatedSource<Task> _paged(
    Query<Map<String, dynamic>> query,
    String label,
  ) => FirestorePaginatedQuery<Task>(
    query: query,
    decode: _decode,
    pendingAwareDecode: _decodePending,
    debugLabel: label,
  );

  /// Wraps a write so a synchronous plugin error also becomes an
  /// `AppFailure` (the returned future still completes only when the
  /// server confirms).
  Future<void> _write(Future<void> Function() write) async {
    try {
      await write();
    } catch (error, stackTrace) {
      throw mapError(error, stackTrace);
    }
  }

  Future<void> _update(String taskId, Map<String, Object?> data) =>
      _write(() => _tasks.doc(taskId).update(data));

  @override
  String newTaskId() => _tasks.doc().id;

  @override
  Future<void> create(String taskId, TaskDraft draft) =>
      _write(() => _tasks.doc(taskId).set(_maps.create(draft)));

  @override
  Stream<Task?> watchTask(String taskId) => _tasks
      .doc(taskId)
      .snapshots(includeMetadataChanges: true)
      .map((snap) {
        final data = snap.data();
        if (data == null) return null;
        final task = Task.fromMap(
          snap.id,
          data,
          hasPendingWrites: snap.metadata.hasPendingWrites,
        );
        return task.deleted ? null : task;
      })
      .handleError((Object error, StackTrace stackTrace) {
        throw mapError(error, stackTrace);
      });

  @override
  LivePaginatedSource<Task> myTasks() => _paged(
    _tasks
        .where('assigneeIds', arrayContains: uid)
        .where(
          'assignmentState',
          isEqualTo: AssignmentState.assigned.firestoreValue,
        )
        .where('deleted', isEqualTo: false)
        .where(
          'status',
          whereIn: [for (final s in TaskStatus.openStatuses) s.firestoreValue],
        )
        .orderBy('deadline'),
    'myTasks',
  );

  @override
  LivePaginatedSource<Task> myUnassignedTasks() => _paged(
    _tasks
        .where('viewerIds', arrayContains: uid)
        .where('creatorId', isEqualTo: uid)
        .where(
          'assignmentState',
          whereIn: [
            AssignmentState.pending.firestoreValue,
            AssignmentState.rejected.firestoreValue,
          ],
        )
        .where('deleted', isEqualTo: false)
        .orderBy('deadline'),
    'myUnassignedTasks',
  );

  Query<Map<String, dynamic>> _withFilter(
    Query<Map<String, dynamic>> query,
    TaskFilter filter,
    DateTime now,
  ) {
    var q = query.where('deleted', isEqualTo: false);
    if (filter.status case final status?) {
      q = q.where('status', isEqualTo: status.firestoreValue);
    }
    if (filter.priority case final priority?) {
      q = q.where('priority', isEqualTo: priority.firestoreValue);
    }
    if (filter.due case final due?) {
      final range = deadlineRangeFor(due, now);
      if (range.start case final start?) {
        q = q.where(
          'deadline',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        );
      }
      if (range.end case final end?) {
        q = q.where('deadline', isLessThan: Timestamp.fromDate(end));
      }
    }
    return q.orderBy('deadline');
  }

  @override
  LivePaginatedSource<Task> teamTasks(
    TaskFilter filter, {
    required DateTime now,
  }) => _paged(
    _withFilter(_tasks.where('viewerIds', arrayContains: uid), filter, now),
    'teamTasks',
  );

  @override
  LivePaginatedSource<Task> orgTasks(
    TaskFilter filter, {
    required DateTime now,
  }) => _paged(
    _withFilter(_tasks.where('confidential', isEqualTo: false), filter, now),
    'orgTasks',
  );

  @override
  Future<void> updateDetails(String taskId, TaskEdit edit) =>
      _update(taskId, _maps.edit(edit));

  @override
  Future<void> changeStatus(String taskId, TaskStatus to, {String? reason}) =>
      _update(taskId, _maps.status(to, reason: reason));

  @override
  Future<void> markMyPartDone(String taskId) =>
      _update(taskId, _maps.completeMyPart());

  @override
  Future<void> confirmCheck(String taskId) =>
      _update(taskId, _maps.confirmCheck());

  @override
  Future<void> returnWork(String taskId, String reason) =>
      _update(taskId, _maps.returnWork(reason));

  @override
  Future<void> cancel(String taskId, String reason) =>
      _update(taskId, _maps.cancel(reason));

  @override
  Future<void> softDelete(String taskId) => _update(taskId, _maps.softDelete());

  @override
  Future<void> resubmit(String taskId, TaskDraft draft) =>
      _update(taskId, _maps.resubmit(draft));

  @override
  Future<void> discard(String taskId) => _update(taskId, _maps.softDelete());

  @override
  Future<void> reassign(String taskId, List<String> assigneeIds) async {
    await _callables().call('reassignTask', {
      'taskId': taskId,
      'assigneeIds': assigneeIds,
    });
  }
}
