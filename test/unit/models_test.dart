import 'package:atms/shared/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final deadline = DateTime.utc(2026, 10, 20, 14, 30);

  Task fullTask() => Task(
    id: 't1',
    title: 'Purchase 5 laptops',
    description: 'For the finance team',
    priority: TaskPriority.urgent,
    status: TaskStatus.inProgress,
    deadline: deadline,
    creatorId: 'u-creator',
    assigneeIds: const ['u-a', 'u-b'],
    deptId: 'finance',
    confidential: true,
    participantIds: const ['u-a', 'u-b', 'u-creator'],
    viewerIds: const ['u-a', 'u-b', 'u-creator'],
    templateId: 'purchase',
    templateVersion: 3,
    currentStep: 2,
    stepDeadline: deadline.subtract(const Duration(days: 1)),
    escalationLevel: 1,
    overdue: true,
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: DateTime.utc(2026, 10, 2),
    completionMode: CompletionMode.any,
    completedByIds: const ['u-a'],
    blockedReason: 'waiting',
    cancelReason: null,
  );

  group('enums use the Firestore values from the spec', () {
    test('TaskStatus', () {
      expect(TaskStatus.values.map((s) => s.firestoreValue), [
        'todo',
        'in_progress',
        'blocked',
        'done',
        'cancelled',
      ]);
      for (final s in TaskStatus.values) {
        expect(TaskStatus.fromFirestore(s.firestoreValue), s);
      }
      expect(
        () => TaskStatus.fromFirestore('inProgress'),
        throwsFormatException,
      );
    });

    test('other enums round-trip', () {
      for (final v in TaskPriority.values) {
        expect(TaskPriority.fromFirestore(v.firestoreValue), v);
      }
      for (final v in UserRole.values) {
        expect(UserRole.fromFirestore(v.firestoreValue), v);
      }
      for (final v in StepOwnerType.values) {
        expect(StepOwnerType.fromFirestore(v.firestoreValue), v);
      }
      for (final v in CompletionMode.values) {
        expect(CompletionMode.fromFirestore(v.firestoreValue), v);
      }
      expect(TransitionAction.values.map((a) => a.firestoreValue), [
        'submit',
        'approve',
        'reject',
        'sendBack',
      ]);
      for (final v in TransitionAction.values) {
        expect(TransitionAction.fromFirestore(v.firestoreValue), v);
      }
      expect(() => UserRole.fromFirestore('superuser'), throwsFormatException);
    });

    test('reject and send back need a comment', () {
      expect(TransitionAction.reject.requiresComment, isTrue);
      expect(TransitionAction.sendBack.requiresComment, isTrue);
      expect(TransitionAction.approve.requiresComment, isFalse);
    });
  });

  group('Task', () {
    test('toMap / fromMap round-trip', () {
      final task = fullTask();
      final map = task.toMap();
      expect(map['status'], 'in_progress');
      expect(map['deadline'], isA<Timestamp>());
      expect(Task.fromMap('t1', map), task);
    });

    test('fromMap applies defaults for optional fields', () {
      final task = Task.fromMap('t2', {
        'title': 'Report',
        'priority': 'low',
        'status': 'todo',
        'deadline': Timestamp.fromDate(deadline),
        'creatorId': 'u1',
        'assigneeIds': ['u1'],
        'deptId': 'ict',
      });
      expect(task.description, '');
      expect(task.confidential, isFalse);
      expect(task.escalationLevel, 0);
      expect(task.completionMode, CompletionMode.all);
      expect(task.viewerIds, isEmpty);
    });

    test('fromMap rejects a missing title', () {
      expect(
        () => Task.fromMap('x', {'priority': 'low', 'status': 'todo'}),
        throwsFormatException,
      );
    });

    test('toClientCreateMap excludes every server-only field', () {
      final map = fullTask().toClientCreateMap();
      for (final field in Task.serverOnlyFields) {
        expect(map.containsKey(field), isFalse, reason: field);
      }
      for (final field in const [
        'viewerIds',
        'currentStep',
        'escalationLevel',
        'templateVersion',
        'stepDeadline',
        'overdue',
      ]) {
        expect(map.containsKey(field), isFalse, reason: field);
      }
      expect(map.keys.toSet(), Task.clientCreateFields);
      expect(map.containsKey('id'), isFalse);
    });

    test('toClientCreateMap always creates a "todo" task with server time', () {
      final map = fullTask().toClientCreateMap();
      expect(map['status'], 'todo');
      expect(map['createdAt'], isA<FieldValue>());
      expect(map['updatedAt'], isA<FieldValue>());
    });

    test('participants are only sent for confidential tasks', () {
      final normal = Task(
        id: 'n',
        title: 'x',
        priority: TaskPriority.low,
        status: TaskStatus.todo,
        deadline: deadline,
        creatorId: 'c',
        assigneeIds: const ['a'],
        deptId: 'd',
        participantIds: const ['a', 'c'],
      );
      expect(normal.toClientCreateMap()['participantIds'], isEmpty);
    });

    test('toString never contains the title', () {
      expect(fullTask().toString(), isNot(contains('laptops')));
    });
  });

  group('AppUser', () {
    const user = AppUser(
      id: 'u1',
      orgId: 'org1',
      name: 'Asha',
      role: UserRole.staff,
      deptId: 'finance',
      supervisorId: 'u2',
      managerChain: ['u2', 'u3'],
      confidentialDepts: ['hr'],
      language: 'sw',
    );

    test('round-trip', () {
      expect(AppUser.fromMap('u1', user.toMap(), orgId: 'org1'), user);
    });

    test('self update only contains language', () {
      expect(user.toSelfUpdateMap().keys, ['language']);
    });

    test('confidential access check', () {
      expect(user.hasConfidentialAccessTo('hr'), isTrue);
      expect(user.hasConfidentialAccessTo('finance'), isFalse);
    });
  });

  test('Department round-trip', () {
    const dept = Department(id: 'd1', name: 'Finance', headUserId: 'u9');
    expect(Department.fromMap('d1', dept.toMap()), dept);
  });

  group('TransitionRequest', () {
    final request = TransitionRequest(
      id: 'r1',
      taskId: 't1',
      fromStep: 3,
      action: TransitionAction.sendBack,
      toStep: 1,
      comment: 'Missing quote',
      requestedBy: 'u1',
      result: TransitionResult(
        status: TransitionResultStatus.rejected,
        reasonCode: 'already_moved',
        rejectedBecauseActor: 'John',
        at: DateTime.utc(2026, 10, 5, 10, 42),
      ),
    );

    test('round-trip including result', () {
      expect(TransitionRequest.fromMap('r1', request.toMap()), request);
    });

    test('client create map never contains result', () {
      final map = request.toClientCreateMap();
      expect(map.containsKey('result'), isFalse);
      expect(map['action'], 'sendBack');
    });
  });
}
