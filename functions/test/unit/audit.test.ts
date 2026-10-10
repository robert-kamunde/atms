import { Timestamp } from 'firebase-admin/firestore';
import {
  auditEntryId, classifyTaskUpdate, createdSnapshot, isMadeOffline, isResubmission, sameValue, userAuditDiff,
} from '../../src/audit/audit';

const T = (ms: number) => Timestamp.fromMillis(ms);
const base = {
  title: 'Budget', description: 'Q3', priority: 'high', status: 'todo', deadline: T(5_000_000), creatorId: 'john',
  assigneeIds: ['asha'], viewerIds: ['john', 'asha', 'neema'], deptId: 'FIN', confidential: false, participantIds: [],
  completionMode: 'all', completedByIds: [], assignmentState: 'assigned', deleted: false, needsCheck: false,
  updatedAt: T(1_000_000), updatedBy: 'john',
};
const write = (by: string, changes: Record<string, unknown>) => ({ ...base, ...changes, updatedBy: by, updatedAt: T(2_000_000) });
const actions = (after: Record<string, unknown>, before: Record<string, unknown> = base) => classifyTaskUpdate(before, after).map((c) => c.action);

describe('isMadeOffline', () => {
  test('true only for a new clientUpdatedAt more than 60 s before the server time', () => {
    expect(isMadeOffline(base, { ...base, updatedAt: T(200_000), clientUpdatedAt: T(100_000) })).toBe(true);
    expect(isMadeOffline(base, { ...base, updatedAt: T(160_000), clientUpdatedAt: T(100_000) })).toBe(false);
    expect(isMadeOffline(base, { ...base, updatedAt: T(200_000) })).toBe(false);
  });
  test('a clientUpdatedAt left from an earlier write does not count', () => {
    const before = { ...base, clientUpdatedAt: T(100_000) };
    expect(isMadeOffline(before, { ...before, updatedAt: T(900_000) })).toBe(false);
  });
  test('creation uses createdAt when there is no updatedAt', () => {
    expect(isMadeOffline(null, { createdAt: T(500_000), clientUpdatedAt: T(100_000) })).toBe(true);
  });
});

describe('classifyTaskUpdate', () => {
  test('status changes', () => {
    expect(classifyTaskUpdate(base, write('asha', { status: 'in_progress' }))).toEqual([
      { action: 'status_changed', before: { status: 'todo' }, after: { status: 'in_progress' } },
    ]);
    expect(classifyTaskUpdate(base, write('asha', { status: 'blocked', blockedReason: 'waiting' }))[0].after)
      .toEqual({ status: 'blocked', blockedReason: 'waiting' });
    expect(actions(write('john', { status: 'cancelled', cancelReason: 'no' }))).toEqual(['task_cancelled']);
    const awaiting = { ...base, status: 'awaiting_check' };
    expect(classifyTaskUpdate(awaiting, write('john', { status: 'in_progress', returnReason: 'redo' }))).toEqual([
      { action: 'check_returned', before: { status: 'awaiting_check' }, after: { status: 'in_progress', returnReason: 'redo' } },
    ]);
    expect(actions(write('john', { status: 'done' }), awaiting)).toEqual(['status_changed']);
  });

  test('one entry per action in a multi-field edit', () => {
    const changes = classifyTaskUpdate(base, write('john', { title: 'Budget v2', deadline: T(9_000_000), priority: 'urgent' }));
    expect(changes.map((c) => c.action)).toEqual(['deadline_changed', 'task_edited']);
    expect(changes[1]).toEqual({ action: 'task_edited', before: { title: 'Budget', priority: 'high' }, after: { title: 'Budget v2', priority: 'urgent' } });
    expect(actions(write('john', { needsCheck: true }))).toEqual(['task_edited']);
  });

  test('completion by one assignee, and soft delete', () => {
    expect(actions(write('asha', { completedByIds: ['asha'] }))).toEqual(['task_completed_by']);
    expect(actions(write('idrisa', { deleted: true, deletedAt: T(2_000_000) }))).toEqual(['task_deleted']);
  });

  test('bookkeeping alone is not an action', () => {
    expect(actions(write('john', { clientUpdatedAt: T(1) }))).toEqual([]);
  });

  test('server writes are audited by the server function, not here', () => {
    expect(actions({ ...base, status: 'done', updatedBy: 'system' })).toEqual([]);
    expect(actions({ ...base, viewerIds: ['john', 'asha'] })).toEqual([]);
    expect(actions({ ...base, assignmentState: 'assigned' }, { ...base, assignmentState: 'pending' })).toEqual([]);
    expect(actions(write('john', { assigneeIds: ['baraka'], viewerIds: ['john', 'baraka'] }))).toEqual([]);
    expect(actions({ ...base, reassignmentNeeded: true, reassignmentReason: 'user_deactivated' })).toEqual([]);
  });

  test('a resubmission is one task_edited entry with the creator\'s changes', () => {
    const rejected = { ...base, assignmentState: 'rejected', assignmentError: 'assignee-not-allowed', viewerIds: ['john'] };
    const after = { ...rejected, assignmentState: 'pending', assigneeIds: ['john'], title: 'New', updatedAt: T(3_000_000) } as Record<string, unknown>;
    delete after.assignmentError;
    expect(isResubmission(rejected, after)).toBe(true);
    expect(classifyTaskUpdate(rejected, after)).toEqual([
      { action: 'task_edited', before: { title: 'Budget', assigneeIds: ['asha'] }, after: { title: 'New', assigneeIds: ['john'] } },
    ]);
  });
});

describe('helpers', () => {
  test('entry ids are deterministic and path-safe', () => {
    expect(auditEntryId('abc/12:3', 'task_created')).toBe('abc_12_3-task_created');
    expect(auditEntryId('e1', 'x')).toBe(auditEntryId('e1', 'x'));
  });
  test('sameValue compares timestamps, arrays and maps', () => {
    expect(sameValue(T(5), T(5))).toBe(true);
    expect(sameValue(['a', T(1)], ['a', T(1)])).toBe(true);
    expect(sameValue({ a: [1] }, { a: [1] })).toBe(true);
    expect(sameValue(['a'], ['a', 'b'])).toBe(false);
    expect(sameValue(undefined, null)).toBe(false);
  });
  test('createdSnapshot records the task fields, not bookkeeping or visibility', () => {
    const s = createdSnapshot(base);
    expect(Object.keys(s)).not.toContain('viewerIds');
    expect(Object.keys(s)).not.toContain('updatedBy');
    expect(s.title).toBe('Budget');
  });
  test('userAuditDiff', () => {
    const u = { name: 'Asha', role: 'staff', deptId: 'FIN', supervisorId: 'john', jobRole: null, language: 'en', confidentialDepts: [], active: true, phone: '+255700000005', email: null, managerChain: ['john'] };
    expect(userAuditDiff(null, u)?.before).toBeNull();
    expect(userAuditDiff(null, u)?.after).not.toHaveProperty('managerChain');
    expect(userAuditDiff(u, { ...u, managerChain: ['x'] })).toBeNull();
    expect(userAuditDiff(u, { ...u, role: 'manager' })).toEqual({ before: { role: 'staff' }, after: { role: 'manager' } });
  });
});
