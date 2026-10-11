/**
 * Sprint 2 task handlers against the Auth and Firestore emulators: the assignment check
 * (onTaskCreated, A-01), audit entries and completion (onTaskUpdated, PDD 4.11, A-02, D-06),
 * reassignTask, and viewerIds upkeep when a managerChain changes. The triggers are called
 * directly with the event id the platform would pass, including retries.
 */
import { FieldValue, Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { sendAdminCode, verifyAdminCode } from '../../src/auth/adminCodeHandlers';
import { handleTaskCreated } from '../../src/tasks/assignTask';
import { reassignTask } from '../../src/tasks/reassignTask';
import { handleTaskUpdated } from '../../src/tasks/taskUpdated';
import { handleUserUpdated, recomputeViewerIdsForAssignee } from '../../src/tasks/visibility';
import { ErrorCode } from '../../src/shared/errors';
import { caller, clearEmulators, db, expectCode, makeDeps, ORG, seed, seedPerson, type TestDeps } from './helpers';

jest.setTimeout(120_000);

let deps: TestDeps;
let eventSeq = 0;
const nextEvent = () => `evt-${Date.now()}-${++eventSeq}`;

beforeEach(async () => {
  await clearEmulators();
  await seed();
  // Zuri is a second Finance staff member under John.
  await seedPerson({ uid: 'zuri', role: 'staff', deptId: 'FIN', supervisorId: 'john', managerChain: ['john', 'neema'], phone: '+255700000009' });
  deps = makeDeps();
});

const taskRef = (id: string) => db.doc(`orgs/${ORG}/tasks/${id}`);
const task = async (id: string) => (await taskRef(id).get()).data() as DocumentData;
const entries = async (id: string) => {
  const snap = await db.collection(`orgs/${ORG}/audit`).where('taskId', '==', id).get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }) as DocumentData);
};
const actionsOf = async (id: string) => (await entries(id)).map((e) => e.action as string).sort();

/** Writes a task exactly as the app creates it (pending, creator-only). */
async function appCreates(id: string, creator: string, extra: Record<string, unknown> = {}): Promise<void> {
  await taskRef(id).set({
    title: 'Prepare Q3 budget', description: 'Private details', priority: 'high', deadline: Timestamp.fromMillis(deps.clock.ms + 86_400_000),
    assigneeIds: [creator], deptId: 'FIN', confidential: false, participantIds: [], templateId: null, completionMode: 'all',
    creatorId: creator, status: 'todo', viewerIds: [creator], assignmentState: 'pending', completedByIds: [], deleted: false,
    needsCheck: false, createdAt: Timestamp.fromMillis(deps.clock.ms), updatedAt: Timestamp.fromMillis(deps.clock.ms),
    updatedBy: creator, clientUpdatedAt: Timestamp.fromMillis(deps.clock.ms - 1000), ...extra,
  });
}

async function createdAndChecked(id: string, creator: string, extra: Record<string, unknown> = {}) {
  await appCreates(id, creator, extra);
  return handleTaskCreated(deps, { org: ORG, taskId: id, eventId: nextEvent() });
}

/** Applies a write as the app would and runs the update trigger for it; returns the event id used. */
async function appUpdates(id: string, by: string, changes: Record<string, unknown>, eventId = nextEvent()) {
  const before = await task(id);
  await taskRef(id).update({ ...changes, updatedBy: by, updatedAt: FieldValue.serverTimestamp() });
  const after = await task(id);
  const result = await handleTaskUpdated(deps, { org: ORG, taskId: id, eventId, before, after });
  return { eventId, before, after, result };
}

/** Runs the trigger for a server write already made (the next event in the chain). */
async function serverWrote(id: string, before: DocumentData) {
  const after = await task(id);
  return handleTaskUpdated(deps, { org: ORG, taskId: id, eventId: nextEvent(), before, after });
}

async function setVerification(uid: string, verifiedUntilMs: number) {
  await db.doc(`orgs/${ORG}/secure/adminVerification/admins/${uid}`).set({ verifiedUntilMs });
}

describe('onTaskCreated: assignment check (A-01)', () => {
  test('staff assigning themselves: assigned, viewers are them and their manager chain, two audit entries', async () => {
    expect(await createdAndChecked('t1', 'asha')).toBe('assigned');
    const t = await task('t1');
    expect(t.assignmentState).toBe('assigned');
    expect(t.viewerIds).toEqual(['asha', 'john', 'neema']);
    expect(t.assignmentError).toBeUndefined();
    const es = await entries('t1');
    expect(es.map((e) => e.action).sort()).toEqual(['task_assigned', 'task_created']);
    const created = es.find((e) => e.action === 'task_created')!;
    expect(created.actorId).toBe('asha');
    expect(created.viewerIds).toEqual(['asha', 'john', 'neema']);
    expect(created.madeOffline).toBe(false);
    expect(created.after.title).toBe('Prepare Q3 budget');
    expect(es.find((e) => e.action === 'task_assigned')!.actorId).toBe('system');
  });

  test('staff assigning someone else: rejected, creator-only, with the reason', async () => {
    expect(await createdAndChecked('t1', 'asha', { assigneeIds: ['zuri'] })).toBe('rejected');
    const t = await task('t1');
    expect(t.assignmentState).toBe('rejected');
    expect(t.assignmentError).toBe(ErrorCode.assigneeNotAllowed);
    expect(t.viewerIds).toEqual(['asha']);
    const es = await entries('t1');
    expect(es.map((e) => e.action).sort()).toEqual(['task_created', 'task_rejected']);
    for (const e of es) expect(e.viewerIds).toEqual(['asha']);
  });

  test('a manager assigns their tree but not someone outside it', async () => {
    expect(await createdAndChecked('in', 'john', { assigneeIds: ['asha', 'zuri'] })).toBe('assigned');
    expect((await task('in')).viewerIds).toEqual(['john', 'asha', 'zuri', 'neema']);
    expect(await createdAndChecked('out', 'john', { assigneeIds: ['asha', 'baraka'] })).toBe('rejected');
    expect((await task('out')).assignmentError).toBe(ErrorCode.assigneeNotAllowed);
  });

  test('an admin without a valid second factor at creation is refused; a verified admin assigns anyone', async () => {
    expect(await createdAndChecked('noRecord', 'idrisa', { assigneeIds: ['baraka'] })).toBe('rejected');
    await setVerification('idrisa', deps.clock.ms - 1);
    expect(await createdAndChecked('expired', 'idrisa', { assigneeIds: ['baraka'] })).toBe('rejected');
    expect((await task('expired')).assignmentError).toBe(ErrorCode.assigneeNotAllowed);
    await setVerification('idrisa', deps.clock.ms + 3_600_000);
    expect(await createdAndChecked('ok', 'idrisa', { assigneeIds: ['baraka'] })).toBe('assigned');
    expect((await task('ok')).viewerIds).toEqual(['idrisa', 'baraka', 'grace', 'neema']);
  });

  test('verifyAdminCode writes the verification record the trigger reads', async () => {
    const c = caller(deps, 'idrisa', { verified: false });
    await sendAdminCode(deps, c, {});
    const code = /(\d{6})/.exec(deps.emailOut.sent[0].text)?.[1] as string;
    const res = await verifyAdminCode(deps, c, { code });
    const rec = (await db.doc(`orgs/${ORG}/secure/adminVerification/admins/idrisa`).get()).data();
    expect(rec).toEqual({ verifiedUntilMs: res.verifiedUntil });
    expect(await createdAndChecked('afterCode', 'idrisa', { assigneeIds: ['baraka'] })).toBe('assigned');
  });

  test('inactive or unknown people and inactive departments are refused', async () => {
    expect(await createdAndChecked('a', 'john', { assigneeIds: ['gone'] })).toBe('rejected');
    expect((await task('a')).assignmentError).toBe(ErrorCode.assigneeInactive);
    expect(await createdAndChecked('b', 'john', { assigneeIds: ['asha'], participantIds: ['gone'] })).toBe('rejected');
    expect((await task('b')).assignmentError).toBe(ErrorCode.assigneeInactive);
    expect(await createdAndChecked('c', 'john', { assigneeIds: ['nobody'] })).toBe('rejected');
    expect((await task('c')).assignmentError).toBe(ErrorCode.assigneeInactive);
    expect(await createdAndChecked('d', 'john', { assigneeIds: ['asha'], deptId: 'OLD' })).toBe('rejected');
    expect((await task('d')).assignmentError).toBe(ErrorCode.departmentInvalid);
    expect(await createdAndChecked('e', 'john', { assigneeIds: ['asha'], deptId: 'NOPE' })).toBe('rejected');
    expect((await task('e')).assignmentError).toBe(ErrorCode.departmentInvalid);
  });

  test('a deactivated creator cannot assign', async () => {
    await db.doc(`orgs/${ORG}/users/john`).update({ active: false });
    expect(await createdAndChecked('t', 'john', { assigneeIds: ['asha'] })).toBe('rejected');
  });

  test('CRITICAL: a confidential task\'s viewerIds never include managers', async () => {
    await db.doc(`orgs/${ORG}/users/john`).update({ confidentialDepts: ['FIN'] });
    expect(await createdAndChecked('conf', 'john', { confidential: true, assigneeIds: ['asha'], participantIds: ['zuri'] })).toBe('assigned');
    const t = await task('conf');
    expect(t.viewerIds).toEqual(['john', 'asha', 'zuri']);
    expect(t.viewerIds).not.toContain('neema');
    for (const e of await entries('conf')) {
      expect(e.confidential).toBe(true);
      expect(e.viewerIds).toEqual(['john', 'asha', 'zuri']);
    }
  });

  test('retries are idempotent: the same event twice gives one assignment and one entry per action', async () => {
    await appCreates('t1', 'asha');
    const eventId = nextEvent();
    expect(await handleTaskCreated(deps, { org: ORG, taskId: 't1', eventId })).toBe('assigned');
    expect(await handleTaskCreated(deps, { org: ORG, taskId: 't1', eventId })).toBe('not-pending');
    expect(await handleTaskCreated(deps, { org: ORG, taskId: 't1', eventId: nextEvent() })).toBe('not-pending');
    expect(await actionsOf('t1')).toEqual(['task_assigned', 'task_created']);
    // The server's own assignment write produces no further entry.
    const before = { ...(await task('t1')), assignmentState: 'pending', viewerIds: ['asha'] };
    await serverWrote('t1', before);
    expect(await actionsOf('t1')).toEqual(['task_assigned', 'task_created']);
  });

  test('a task created offline is marked madeOffline', async () => {
    await createdAndChecked('off', 'asha', { clientUpdatedAt: Timestamp.fromMillis(deps.clock.ms - 5 * 60_000) });
    const created = (await entries('off')).find((e) => e.action === 'task_created')!;
    expect(created.madeOffline).toBe(true);
  });

  test('workflow tasks are left for Sprint 3; a task discarded before the check is only recorded', async () => {
    expect(await createdAndChecked('wf', 'john', { templateId: 'purchase' })).toBe('workflow-deferred');
    expect((await task('wf')).assignmentState).toBe('pending');
    expect(await createdAndChecked('gone', 'asha', { deleted: true })).toBe('discarded');
    expect(await actionsOf('gone')).toEqual(['task_created']);
    expect((await task('gone')).assignmentState).toBe('pending');
  });
});

describe('onTaskUpdated: audit entries (PDD 4.11)', () => {
  beforeEach(async () => {
    await createdAndChecked('t', 'john', { assigneeIds: ['asha'] });
  });

  test('status changes, deadline change and edits each give exactly one entry', async () => {
    await appUpdates('t', 'asha', { status: 'in_progress' });
    await appUpdates('t', 'asha', { status: 'blocked', blockedReason: 'Waiting for invoices' });
    await appUpdates('t', 'john', { deadline: Timestamp.fromMillis(deps.clock.ms + 3 * 86_400_000), title: 'Q3 budget v2' });
    await appUpdates('t', 'john', { status: 'cancelled', cancelReason: 'Not needed' });
    expect(await actionsOf('t')).toEqual([
      'deadline_changed', 'status_changed', 'status_changed', 'task_assigned', 'task_cancelled', 'task_created', 'task_edited',
    ]);
    const blocked = (await entries('t')).find((e) => e.action === 'status_changed' && e.after.status === 'blocked')!;
    expect(blocked).toMatchObject({ actorId: 'asha', before: { status: 'in_progress' }, after: { status: 'blocked', blockedReason: 'Waiting for invoices' } });
    expect(blocked.viewerIds).toEqual(['john', 'asha', 'neema']);
    expect(blocked.at).toBeInstanceOf(Timestamp);
  });

  test('retry: the same event twice writes one entry', async () => {
    const { eventId, before, after } = await appUpdates('t', 'asha', { status: 'in_progress' });
    const again = await handleTaskUpdated(deps, { org: ORG, taskId: 't', eventId, before, after });
    expect(again.entries).toEqual([]);
    expect((await entries('t')).filter((e) => e.action === 'status_changed')).toHaveLength(1);
  });

  test('madeOffline: a change queued on the phone for more than 60 seconds', async () => {
    const { after } = await appUpdates('t', 'asha', { status: 'in_progress', clientUpdatedAt: Timestamp.fromMillis(Date.now() - 10 * 60_000) });
    expect(after.clientUpdatedAt).toBeDefined();
    const e = (await entries('t')).find((x) => x.action === 'status_changed')!;
    expect(e.madeOffline).toBe(true);
    await appUpdates('t', 'asha', { status: 'blocked', blockedReason: 'x', clientUpdatedAt: Timestamp.fromMillis(Date.now()) });
    const online = (await entries('t')).find((x) => x.action === 'status_changed' && x.after.status === 'blocked')!;
    expect(online.madeOffline).toBe(false);
  });

  test('soft delete is logged', async () => {
    await appUpdates('t', 'john', { deleted: true, deletedAt: FieldValue.serverTimestamp() });
    expect((await entries('t')).filter((e) => e.action === 'task_deleted')).toHaveLength(1);
  });
});

describe('onTaskUpdated: completion (A-02, D-06)', () => {
  test('all mode: done only once every assignee has finished, exactly once', async () => {
    await createdAndChecked('s', 'john', { assigneeIds: ['asha', 'zuri'] });
    const first = await appUpdates('s', 'asha', { completedByIds: ['asha'] });
    expect(first.result.completedTo).toBeNull();
    expect((await task('s')).status).toBe('todo');
    const second = await appUpdates('s', 'zuri', { completedByIds: ['asha', 'zuri'] });
    expect(second.result.completedTo).toBe('done');
    const t = await task('s');
    expect(t.status).toBe('done');
    expect(t.updatedBy).toBe('system');
    // Retry of the completing event, and the event of the server's own write: nothing more.
    expect((await handleTaskUpdated(deps, { org: ORG, taskId: 's', eventId: second.eventId, before: second.before, after: second.after })).entries).toEqual([]);
    expect((await serverWrote('s', second.after)).entries).toEqual([]);
    const es = await entries('s');
    expect(es.filter((e) => e.action === 'task_completed_by')).toHaveLength(2);
    const sys = es.filter((e) => e.action === 'status_changed');
    expect(sys).toHaveLength(1);
    expect(sys[0]).toMatchObject({ actorId: 'system', before: { status: 'todo' }, after: { status: 'done' } });
  });

  test('all mode with a creator check: awaiting_check; a return clears completions for a fresh round', async () => {
    await createdAndChecked('s', 'john', { assigneeIds: ['asha', 'zuri'], needsCheck: true });
    await appUpdates('s', 'asha', { completedByIds: ['asha'] });
    const done = await appUpdates('s', 'zuri', { completedByIds: ['asha', 'zuri'] });
    expect(done.result.completedTo).toBe('awaiting_check');
    expect((await task('s')).status).toBe('awaiting_check');

    const ret = await appUpdates('s', 'john', { status: 'in_progress', returnReason: 'Totals are wrong' });
    expect(ret.result.completedByReset).toBe(true);
    let t = await task('s');
    expect(t.status).toBe('in_progress');
    expect(t.completedByIds).toEqual([]);
    await serverWrote('s', ret.after);
    expect((await task('s')).status).toBe('in_progress');
    expect((await entries('s')).filter((e) => e.action === 'check_returned')).toHaveLength(1);
    expect((await entries('s')).find((e) => e.action === 'check_returned')!.after).toEqual({ status: 'in_progress', returnReason: 'Totals are wrong' });

    await appUpdates('s', 'asha', { completedByIds: ['asha'] });
    await appUpdates('s', 'zuri', { completedByIds: ['asha', 'zuri'] });
    expect((await task('s')).status).toBe('awaiting_check');
    await appUpdates('s', 'john', { status: 'done' });
    t = await task('s');
    expect(t.status).toBe('done');
  });

  test('concurrent completions produce one transition', async () => {
    await createdAndChecked('s', 'john', { assigneeIds: ['asha', 'zuri'] });
    const before = await task('s');
    await taskRef('s').update({ completedByIds: ['asha', 'zuri'], updatedBy: 'zuri', updatedAt: FieldValue.serverTimestamp() });
    const after = await task('s');
    const mid = { ...after, completedByIds: ['asha'], updatedBy: 'asha' };
    await Promise.all([
      handleTaskUpdated(deps, { org: ORG, taskId: 's', eventId: 'e-a', before, after: mid }),
      handleTaskUpdated(deps, { org: ORG, taskId: 's', eventId: 'e-z', before: mid, after }),
    ]);
    expect((await entries('s')).filter((e) => e.action === 'status_changed')).toHaveLength(1);
    expect((await task('s')).status).toBe('done');
  });
});

describe('onTaskUpdated: resubmitting a rejected task (A-01)', () => {
  test('the creator fixes the assignees; the check runs again and is audited once', async () => {
    await createdAndChecked('r', 'asha', { assigneeIds: ['zuri'] });
    expect((await task('r')).assignmentState).toBe('rejected');
    const { eventId, before, after, result } = await appUpdates('r', 'asha', {
      assigneeIds: ['asha'], title: 'Fixed', assignmentState: 'pending', assignmentError: FieldValue.delete(),
    });
    expect(result.resubmission).toBe('assigned');
    const t = await task('r');
    expect(t.assignmentState).toBe('assigned');
    expect(t.viewerIds).toEqual(['asha', 'john', 'neema']);
    await handleTaskUpdated(deps, { org: ORG, taskId: 'r', eventId, before, after });
    expect(await actionsOf('r')).toEqual(['task_assigned', 'task_created', 'task_edited', 'task_rejected']);
    const edited = (await entries('r')).find((e) => e.action === 'task_edited')!;
    expect(edited.before).toEqual({ title: 'Prepare Q3 budget', assigneeIds: ['zuri'] });
    expect(edited.viewerIds).toEqual(['asha', 'john', 'neema']);
  });

  test('a resubmission that is still not allowed is rejected again', async () => {
    await createdAndChecked('r', 'asha', { assigneeIds: ['zuri'] });
    const { result } = await appUpdates('r', 'asha', { assigneeIds: ['baraka'], assignmentState: 'pending', assignmentError: FieldValue.delete() });
    expect(result.resubmission).toBe('rejected');
    expect(await task('r')).toMatchObject({ assignmentState: 'rejected', assignmentError: ErrorCode.assigneeNotAllowed, viewerIds: ['asha'] });
  });
});

describe('reassignTask', () => {
  beforeEach(async () => {
    await createdAndChecked('t', 'john', { assigneeIds: ['asha', 'zuri'] });
    await taskRef('t').update({ completedByIds: ['zuri'], reassignmentNeeded: true, reassignmentReason: 'user_deactivated' });
  });

  test('the creator reassigns within their tree: assignees, completions, viewers, flag and one audit entry', async () => {
    expect(await reassignTask(deps, caller(deps, 'john'), { taskId: 't', assigneeIds: ['zuri'] })).toEqual({ ok: true });
    const t = await task('t');
    expect(t.assigneeIds).toEqual(['zuri']);
    expect(t.completedByIds).toEqual(['zuri']);
    expect(t.viewerIds).toEqual(['john', 'zuri', 'neema']);
    expect(t.reassignmentNeeded).toBeUndefined();
    expect(t.reassignmentReason).toBeUndefined();
    const es = (await entries('t')).filter((e) => e.action === 'task_reassigned');
    expect(es).toHaveLength(1);
    expect(es[0]).toMatchObject({ actorId: 'john', before: { assigneeIds: ['asha', 'zuri'] }, after: { assigneeIds: ['zuri'] } });
  });

  test('after a reassignment that leaves only finished people, the trigger completes the task', async () => {
    const before = await task('t');
    await reassignTask(deps, caller(deps, 'john'), { taskId: 't', assigneeIds: ['zuri'] });
    const r = await serverWrote('t', before);
    expect(r.completedTo).toBe('done');
    expect(r.entries).toHaveLength(1); // the system status change only; the reassignment was audited by the callable
    expect((await entries('t')).filter((e) => e.action === 'task_reassigned')).toHaveLength(1);
  });

  test('a manager above every current and new assignee may reassign; others may not', async () => {
    await reassignTask(deps, caller(deps, 'neema'), { taskId: 't', assigneeIds: ['asha'] });
    expect((await task('t')).assigneeIds).toEqual(['asha']);
    // Asha (staff assignee) can read it but cannot reassign.
    await expectCode(reassignTask(deps, caller(deps, 'asha'), { taskId: 't', assigneeIds: ['asha'] }), ErrorCode.permissionDenied);
    // Grace cannot read it at all: it looks absent.
    await expectCode(reassignTask(deps, caller(deps, 'grace'), { taskId: 't', assigneeIds: ['baraka'] }), ErrorCode.taskNotFound);
  });

  test('new assignees must pass the creation rule for the caller', async () => {
    await expectCode(reassignTask(deps, caller(deps, 'john'), { taskId: 't', assigneeIds: ['baraka'] }), ErrorCode.assigneeNotAllowed);
    await expectCode(reassignTask(deps, caller(deps, 'john'), { taskId: 't', assigneeIds: ['gone'] }), ErrorCode.assigneeInactive);
    await expectCode(reassignTask(deps, caller(deps, 'john'), { taskId: 't', assigneeIds: ['nobody'] }), ErrorCode.assigneeInactive);
    expect((await task('t')).assigneeIds).toEqual(['asha', 'zuri']);
  });

  test('a verified admin reassigns any non-confidential task; without the second factor it is not found', async () => {
    await expectCode(reassignTask(deps, caller(deps, 'idrisa', { verified: false }), { taskId: 't', assigneeIds: ['baraka'] }), ErrorCode.taskNotFound);
    await reassignTask(deps, caller(deps, 'idrisa'), { taskId: 't', assigneeIds: ['baraka'] });
    expect((await task('t')).viewerIds).toEqual(['john', 'baraka', 'grace', 'neema']);
  });

  test('CRITICAL: confidential tasks are invisible to admins and managers without access', async () => {
    await db.doc(`orgs/${ORG}/users/john`).update({ confidentialDepts: ['FIN'] });
    await createdAndChecked('conf', 'john', { confidential: true, assigneeIds: ['asha'] });
    await expectCode(reassignTask(deps, caller(deps, 'idrisa'), { taskId: 'conf', assigneeIds: ['baraka'] }), ErrorCode.taskNotFound);
    await expectCode(reassignTask(deps, caller(deps, 'neema'), { taskId: 'conf', assigneeIds: ['asha'] }), ErrorCode.taskNotFound);
    await reassignTask(deps, caller(deps, 'john'), { taskId: 'conf', assigneeIds: ['zuri'] });
    expect((await task('conf')).viewerIds).toEqual(['john', 'zuri']);
    const e = (await entries('conf')).find((x) => x.action === 'task_reassigned')!;
    expect(e).toMatchObject({ confidential: true, viewerIds: ['john', 'zuri'] });
  });

  test('closed, deleted, unassigned and workflow tasks are refused', async () => {
    await taskRef('t').update({ status: 'done' });
    await expectCode(reassignTask(deps, caller(deps, 'john'), { taskId: 't', assigneeIds: ['zuri'] }), ErrorCode.taskClosed);
    await taskRef('t').update({ status: 'awaiting_check' });
    await reassignTask(deps, caller(deps, 'john'), { taskId: 't', assigneeIds: ['zuri'] }); // awaiting_check is open
    await taskRef('t').update({ deleted: true });
    await expectCode(reassignTask(deps, caller(deps, 'john'), { taskId: 't', assigneeIds: ['zuri'] }), ErrorCode.taskNotFound);
    await createdAndChecked('rej', 'asha', { assigneeIds: ['zuri'] });
    await expectCode(reassignTask(deps, caller(deps, 'asha'), { taskId: 'rej', assigneeIds: ['asha'] }), ErrorCode.validation);
    await createdAndChecked('wf', 'john', { templateId: 'purchase' });
    await taskRef('wf').update({ assignmentState: 'assigned', viewerIds: ['john'] });
    await expectCode(reassignTask(deps, caller(deps, 'john'), { taskId: 'wf', assigneeIds: ['asha'] }), ErrorCode.validation);
    await expectCode(reassignTask(deps, caller(deps, 'john'), { taskId: 'missing', assigneeIds: ['asha'] }), ErrorCode.taskNotFound);
  });

  test('input is validated', async () => {
    const c = caller(deps, 'john');
    await expectCode(reassignTask(deps, c, { taskId: 't', assigneeIds: [] }), ErrorCode.validation);
    await expectCode(reassignTask(deps, c, { taskId: 't', assigneeIds: ['zuri', 'zuri'] }), ErrorCode.validation);
    await expectCode(reassignTask(deps, c, { taskId: 'a/b', assigneeIds: ['zuri'] }), ErrorCode.validation);
    await expectCode(reassignTask(deps, c, { taskId: 't', assigneeIds: ['zuri'], extra: 1 }), ErrorCode.validation);
    await expectCode(reassignTask(deps, c, { taskId: 't', assigneeIds: Array.from({ length: 51 }, (_, i) => `u${i}`) }), ErrorCode.validation);
    await expectCode(reassignTask(deps, undefined, { taskId: 't', assigneeIds: ['zuri'] }), ErrorCode.unauthenticated);
  });
});

describe('visibility upkeep when a managerChain changes', () => {
  test('recomputes viewerIds of every task of the assignee over several pages (>200 tasks)', async () => {
    const N = 205;
    const ts = Timestamp.fromMillis(deps.clock.ms);
    for (let start = 0; start < N; start += 100) {
      const batch = db.batch();
      for (let i = start; i < Math.min(N, start + 100); i++) {
        batch.set(taskRef(`bulk${String(i).padStart(3, '0')}`), {
          title: 'x', creatorId: 'asha', assigneeIds: ['asha'], participantIds: [], confidential: false, deptId: 'FIN',
          status: i % 2 === 0 ? 'done' : 'in_progress', templateId: null, assignmentState: 'assigned', deleted: false,
          viewerIds: ['asha', 'john', 'neema'], completionMode: 'all', completedByIds: [], createdAt: ts, updatedAt: ts, updatedBy: 'asha',
        });
      }
      await batch.commit();
    }
    await taskRef('confA').set({
      title: 'c', creatorId: 'asha', assigneeIds: ['asha'], participantIds: [], confidential: true, deptId: 'FIN', status: 'todo',
      templateId: null, assignmentState: 'assigned', deleted: false, viewerIds: ['asha'], completionMode: 'all', completedByIds: [],
    });
    await taskRef('pendingA').set({
      title: 'p', creatorId: 'asha', assigneeIds: ['asha'], participantIds: [], confidential: false, deptId: 'FIN', status: 'todo',
      templateId: null, assignmentState: 'pending', deleted: false, viewerIds: ['asha'], completionMode: 'all', completedByIds: [],
    });

    // Asha moves from John's team to Grace's.
    const before = (await db.doc(`orgs/${ORG}/users/asha`).get()).data();
    await db.doc(`orgs/${ORG}/users/asha`).update({ supervisorId: 'grace', managerChain: ['grace', 'neema'] });
    const after = (await db.doc(`orgs/${ORG}/users/asha`).get()).data();
    expect(await handleUserUpdated(deps, { org: ORG, uid: 'asha', before, after })).toBe(N);

    const all = await db.collection(`orgs/${ORG}/tasks`).where('assigneeIds', 'array-contains', 'asha').get();
    for (const d of all.docs) {
      if (d.id === 'confA') expect(d.data().viewerIds).toEqual(['asha']);
      else if (d.id === 'pendingA') expect(d.data().viewerIds).toEqual(['asha']);
      else expect(d.data().viewerIds).toEqual(['asha', 'grace', 'neema']);
    }
    // Idempotent: a retry changes nothing; a write that does not change the chain does nothing.
    expect(await recomputeViewerIdsForAssignee(deps, ORG, 'asha')).toBe(0);
    expect(await handleUserUpdated(deps, { org: ORG, uid: 'asha', before: after, after: { ...after, language: 'sw' } })).toBeNull();
  });

  test('other assignees\' managers stay viewers', async () => {
    await createdAndChecked('two', 'neema', { assigneeIds: ['asha', 'baraka'] });
    expect((await task('two')).viewerIds).toEqual(['neema', 'asha', 'baraka', 'john', 'grace']);
    await db.doc(`orgs/${ORG}/users/asha`).update({ supervisorId: 'grace', managerChain: ['grace', 'neema'] });
    await recomputeViewerIdsForAssignee(deps, ORG, 'asha');
    expect((await task('two')).viewerIds).toEqual(['neema', 'asha', 'baraka', 'grace']);
  });
});
