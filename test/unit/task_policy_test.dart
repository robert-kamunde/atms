import 'package:atms/features/tasks/domain/task_policy.dart';
import 'package:atms/shared/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/task_fixtures.dart';

/// These tests mirror the task section of firestore.rules and the Sprint 2
/// contract: the app must only offer changes the server accepts.
void main() {
  const asha = TaskActor(uid: 'asha', role: UserRole.staff);
  const baraka = TaskActor(uid: 'baraka', role: UserRole.staff);
  const creator = TaskActor(uid: 'creator', role: UserRole.staff);
  const managerCreator = TaskActor(uid: 'creator', role: UserRole.manager);
  const otherManager = TaskActor(uid: 'grace', role: UserRole.manager);
  const admin = TaskActor(
    uid: 'idrisa',
    role: UserRole.admin,
    isVerifiedAdmin: true,
  );
  const unverifiedAdmin = TaskActor(uid: 'idrisa', role: UserRole.admin);

  bool can(TaskAction a, Task t, TaskActor who) => TaskPolicy.can(a, t, who);

  group('assignee status changes (rules: assigneeStatusChange)', () {
    test('todo -> in progress, only by an assignee', () {
      final t = taskFixture();
      expect(can(TaskAction.start, t, asha), isTrue);
      expect(can(TaskAction.start, t, creator), isFalse);
      expect(can(TaskAction.start, t, admin), isFalse);
      expect(
        can(TaskAction.start, taskFixture(status: TaskStatus.inProgress), asha),
        isFalse,
      );
    });

    test('in progress -> blocked; blocked -> in progress', () {
      final working = taskFixture(status: TaskStatus.inProgress);
      final blocked = taskFixture(status: TaskStatus.blocked);
      expect(can(TaskAction.block, working, asha), isTrue);
      expect(can(TaskAction.block, taskFixture(), asha), isFalse);
      expect(can(TaskAction.resume, blocked, asha), isTrue);
      expect(can(TaskAction.resume, working, asha), isFalse);
      expect(can(TaskAction.block, working, baraka), isFalse);
    });

    test('done from todo or in progress, single assignee or mode any', () {
      expect(can(TaskAction.markDone, taskFixture(), asha), isTrue);
      expect(
        can(
          TaskAction.markDone,
          taskFixture(status: TaskStatus.inProgress),
          asha,
        ),
        isTrue,
      );
      expect(
        can(TaskAction.markDone, taskFixture(status: TaskStatus.blocked), asha),
        isFalse,
      );
      final several = taskFixture(assigneeIds: ['asha', 'baraka']);
      expect(can(TaskAction.markDone, several, asha), isFalse);
      final any = taskFixture(
        assigneeIds: ['asha', 'baraka'],
        completionMode: CompletionMode.any,
      );
      expect(can(TaskAction.markDone, any, baraka), isTrue);
    });

    test('done goes to waiting for check when the creator asked (D-06)', () {
      expect(TaskPolicy.doneTarget(taskFixture()), TaskStatus.done);
      expect(
        TaskPolicy.doneTarget(taskFixture(needsCheck: true)),
        TaskStatus.awaitingCheck,
      );
    });
  });

  group('several assignees who must all finish (rules: assigneeCompletes)', () {
    final several = taskFixture(
      assigneeIds: ['asha', 'baraka'],
      status: TaskStatus.inProgress,
    );

    test('each assignee adds only themselves, once, while open', () {
      expect(can(TaskAction.markMyPartDone, several, asha), isTrue);
      expect(can(TaskAction.markMyPartDone, several, creator), isFalse);
      final ashaDone = taskFixture(
        assigneeIds: ['asha', 'baraka'],
        completedByIds: ['asha'],
      );
      expect(can(TaskAction.markMyPartDone, ashaDone, asha), isFalse);
      expect(can(TaskAction.markMyPartDone, ashaDone, baraka), isTrue);
      final waiting = taskFixture(
        assigneeIds: ['asha', 'baraka'],
        status: TaskStatus.awaitingCheck,
      );
      expect(can(TaskAction.markMyPartDone, waiting, asha), isFalse);
    });

    test('not offered with one assignee or mode any', () {
      expect(can(TaskAction.markMyPartDone, taskFixture(), asha), isFalse);
      final any = taskFixture(
        assigneeIds: ['asha', 'baraka'],
        completionMode: CompletionMode.any,
      );
      expect(can(TaskAction.markMyPartDone, any, asha), isFalse);
    });
  });

  group('creator check (D-06)', () {
    final waiting = taskFixture(
      status: TaskStatus.awaitingCheck,
      needsCheck: true,
    );

    test('only the creator confirms or returns, only while waiting', () {
      expect(can(TaskAction.confirmCheck, waiting, creator), isTrue);
      expect(can(TaskAction.returnWork, waiting, creator), isTrue);
      expect(can(TaskAction.confirmCheck, waiting, asha), isFalse);
      expect(can(TaskAction.returnWork, waiting, admin), isFalse);
      expect(can(TaskAction.confirmCheck, taskFixture(), creator), isFalse);
    });

    test('waiting for check is not open for edits or cancel', () {
      expect(can(TaskAction.edit, waiting, creator), isFalse);
      expect(can(TaskAction.cancel, waiting, creator), isFalse);
    });
  });

  group('cancel (rules: cancelSimpleTask)', () {
    test('creator or any manager, open simple tasks only', () {
      final t = taskFixture(status: TaskStatus.inProgress);
      expect(can(TaskAction.cancel, t, creator), isTrue);
      expect(can(TaskAction.cancel, t, otherManager), isTrue);
      expect(can(TaskAction.cancel, t, asha), isFalse);
      // The rules do not give admins cancel unless they created it.
      expect(can(TaskAction.cancel, t, admin), isFalse);
      expect(
        can(TaskAction.cancel, taskFixture(status: TaskStatus.done), creator),
        isFalse,
      );
      expect(
        can(TaskAction.cancel, taskFixture(templateId: 'tpl'), creator),
        isFalse,
      );
    });
  });

  group('edit (rules: creatorEdit)', () {
    test('creator only, open tasks', () {
      expect(can(TaskAction.edit, taskFixture(), creator), isTrue);
      expect(can(TaskAction.edit, taskFixture(), asha), isFalse);
      expect(can(TaskAction.edit, taskFixture(), admin), isFalse);
      expect(
        can(
          TaskAction.edit,
          taskFixture(status: TaskStatus.cancelled),
          creator,
        ),
        isFalse,
      );
    });
  });

  group('delete (rules: softDelete)', () {
    test('verified admin any task; manager own task before work starts', () {
      expect(can(TaskAction.delete, taskFixture(), admin), isTrue);
      expect(can(TaskAction.delete, taskFixture(), unverifiedAdmin), isFalse);
      expect(can(TaskAction.delete, taskFixture(), managerCreator), isTrue);
      expect(
        can(
          TaskAction.delete,
          taskFixture(status: TaskStatus.inProgress),
          managerCreator,
        ),
        isFalse,
      );
      expect(can(TaskAction.delete, taskFixture(), otherManager), isFalse);
      expect(can(TaskAction.delete, taskFixture(), creator), isFalse);
    });
  });

  group('reassign (contract: reassignTask)', () {
    test('creator, managers (server checks the tree), verified admins', () {
      final t = taskFixture(status: TaskStatus.inProgress);
      expect(can(TaskAction.reassign, t, creator), isTrue);
      expect(can(TaskAction.reassign, t, otherManager), isTrue);
      expect(can(TaskAction.reassign, t, admin), isTrue);
      expect(can(TaskAction.reassign, t, asha), isFalse);
      expect(can(TaskAction.reassign, t, unverifiedAdmin), isFalse);
      expect(
        can(TaskAction.reassign, taskFixture(confidential: true), admin),
        isFalse,
      );
      expect(
        can(TaskAction.reassign, taskFixture(status: TaskStatus.done), creator),
        isFalse,
      );
    });

    test('only reassign needs a connection', () {
      for (final action in TaskAction.values) {
        expect(
          TaskPolicy.needsConnection(action),
          action == TaskAction.reassign,
          reason: action.name,
        );
      }
    });
  });

  group('assignment state (A-01)', () {
    test('a pending task allows nothing but discard by its creator', () {
      final pending = taskFixture(assignmentState: AssignmentState.pending);
      expect(TaskPolicy.allowedActions(pending, creator), {TaskAction.discard});
      expect(TaskPolicy.allowedActions(pending, asha), isEmpty);
    });

    test('a refused task can be fixed and sent again, or deleted', () {
      final rejected = taskFixture(
        assignmentState: AssignmentState.rejected,
        assignmentError: 'assignee-not-allowed',
      );
      expect(TaskPolicy.allowedActions(rejected, creator), {
        TaskAction.resubmit,
        TaskAction.discard,
      });
      expect(TaskPolicy.allowedActions(rejected, admin), isEmpty);
    });

    test('deleted tasks allow nothing', () {
      expect(
        TaskPolicy.allowedActions(taskFixture(deleted: true), creator),
        isEmpty,
      );
    });
  });

  group('workflow tasks (Sprint 3)', () {
    test('no status actions; the creator may still edit', () {
      final wf = taskFixture(templateId: 'tpl', status: TaskStatus.inProgress);
      expect(TaskPolicy.allowedActions(wf, asha), isEmpty);
      expect(TaskPolicy.allowedActions(wf, creator), {TaskAction.edit});
    });
  });

  group('who may be assigned (spec 2 matrix)', () {
    const teamMember = AppUser(
      id: 'm1',
      orgId: testOrg,
      name: 'Mwajuma',
      role: UserRole.staff,
      deptId: 'finance',
      managerChain: ['grace', 'neema'],
    );
    final outsider = userFixture(id: 'x1', name: 'Outsider');
    const inactiveMember = AppUser(
      id: 'm2',
      orgId: testOrg,
      name: 'Juma',
      role: UserRole.staff,
      deptId: 'finance',
      managerChain: ['grace'],
      active: false,
    );

    test('staff: only themselves', () {
      expect(assigneeScopeFor(asha), AssigneeScope.selfOnly);
      expect(canOfferAssignee(asha, userFixture(id: 'asha')), isTrue);
      expect(canOfferAssignee(asha, teamMember), isFalse);
    });

    test('managers: themselves and their reporting tree', () {
      expect(assigneeScopeFor(otherManager), AssigneeScope.team);
      expect(canOfferAssignee(otherManager, teamMember), isTrue);
      expect(canOfferAssignee(otherManager, outsider), isFalse);
      expect(canOfferAssignee(otherManager, inactiveMember), isFalse);
    });

    test('admins: anyone, but only with a current second factor', () {
      expect(assigneeScopeFor(admin), AssigneeScope.anyone);
      expect(canOfferAssignee(admin, outsider), isTrue);
      expect(assigneeScopeFor(unverifiedAdmin), AssigneeScope.selfOnly);
      expect(canOfferAssignee(unverifiedAdmin, outsider), isFalse);
    });
  });
}
