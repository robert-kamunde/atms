/**
 * Sprint 2 Security Rules tests (SPRINT2_CONTRACT, D-06, A-01): the creator check
 * (awaiting_check), resubmitting and discarding unassigned tasks, the `deleted == false` create
 * rule, the assignee read branch, and the app's exact list queries. Allowed and denied cases.
 * Run with: npm run test:rules.
 */
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import {
  addDoc, collection, deleteField, doc, getDoc, getDocs, limit, orderBy, query, serverTimestamp, setDoc, updateDoc, where,
} from 'firebase/firestore';
import { as, inDays, makeEnv, minutesAgo, ORG, seed, tasks } from './fixtures';

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await makeEnv();
});
afterAll(async () => {
  await env.cleanup();
});

type Who = Parameters<typeof as>[1];
const db = (who: Who, opts: Parameters<typeof as>[2] = {}) => as(env, who, opts).firestore();
const taskRef = (who: Who, id: string, opts: Parameters<typeof as>[2] = {}) => doc(db(who, opts), `orgs/${ORG}/tasks/${id}`);
const stamp = (uid: string) => ({ updatedAt: serverTimestamp(), updatedBy: uid, clientUpdatedAt: minutesAgo(0) });

const extra = {
  // John asked Asha and checks the work himself (D-06).
  checked: { ...tasks.normal, needsCheck: true, status: 'in_progress' },
  awaiting: { ...tasks.normal, needsCheck: true, status: 'awaiting_check' },
  // Shared task waiting for Grace's check: both assignees finished.
  sharedAwaiting: { ...tasks.shared, needsCheck: true, status: 'awaiting_check', completedByIds: ['baraka', 'asha'] },
  finished: { ...tasks.normal, status: 'done' },
  // Asha asked John to do something; the server refused it.
  rejected: {
    ...tasks.normal, creatorId: 'asha', assigneeIds: ['john'], viewerIds: ['asha'], assignmentState: 'rejected',
    assignmentError: 'assignee-not-allowed', updatedBy: 'asha',
  },
  pending: { ...tasks.normal, creatorId: 'asha', assigneeIds: ['asha'], viewerIds: ['asha'], assignmentState: 'pending', updatedBy: 'asha' },
  // Pending task naming Baraka as assignee: he must not read it before assignment.
  pendingForBaraka: { ...tasks.normal, creatorId: 'grace', assigneeIds: ['baraka'], viewerIds: ['grace'], assignmentState: 'pending', deptId: 'OPS' },
  // Assigned task whose viewerIds have not caught up (assignee read branch).
  assignedNotViewer: { ...tasks.normal, creatorId: 'grace', assigneeIds: ['baraka'], viewerIds: ['grace'], deptId: 'OPS' },
  noDeletedField: (() => { const t: Record<string, unknown> = { ...tasks.normal }; delete t.deleted; return t; })(),
  workflowChecked: { ...tasks.workflow, needsCheck: true },
};

beforeEach(async () => {
  await env.clearFirestore();
  await seed(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    for (const [id, t] of Object.entries(extra)) await setDoc(doc(ctx.firestore(), `orgs/${ORG}/tasks/${id}`), t);
  });
});

const newTask = (uid: string, more: Record<string, unknown> = {}) => ({
  title: 'Collect receipts', description: '', priority: 'medium', deadline: inDays(1), assigneeIds: [uid],
  deptId: 'FIN', confidential: false, participantIds: [], templateId: null, completionMode: 'all',
  creatorId: uid, status: 'todo', viewerIds: [uid], assignmentState: 'pending', completedByIds: [],
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), updatedBy: uid, clientUpdatedAt: minutesAgo(0),
  deleted: false, ...more,
});

describe('creating tasks (Sprint 2 fields)', () => {
  const col = (who: Who) => collection(db(who), `orgs/${ORG}/tasks`);

  test('needsCheck is optional and must be a boolean', async () => {
    await assertSucceeds(addDoc(col('asha'), newTask('asha', { needsCheck: true })));
    await assertSucceeds(addDoc(col('asha'), newTask('asha', { needsCheck: false })));
    await assertSucceeds(addDoc(col('asha'), newTask('asha')));
    await assertFails(addDoc(col('asha'), newTask('asha', { needsCheck: 'yes' })));
  });

  test('tasks are created with deleted == false', async () => {
    const t = newTask('asha') as Record<string, unknown>;
    delete t.deleted;
    await assertFails(addDoc(col('asha'), t));
    await assertFails(addDoc(col('asha'), newTask('asha', { deleted: true })));
  });

  test.each([
    ['assignmentError (server-only)', { assignmentError: 'assignee-not-allowed' }],
    ['returnReason', { returnReason: 'redo' }],
    ['status awaiting_check', { status: 'awaiting_check' }],
    ['assignmentState rejected', { assignmentState: 'rejected' }],
  ])('is refused with %s', async (_label, more) => {
    await assertFails(addDoc(col('asha'), newTask('asha', more)));
  });
});

describe('D-06: assignee Done with and without a creator check', () => {
  test('needsCheck true: Done goes to awaiting_check, never straight to done', async () => {
    await assertFails(updateDoc(taskRef('asha', 'checked'), { status: 'done', ...stamp('asha') }));
    await assertSucceeds(updateDoc(taskRef('asha', 'checked'), { status: 'awaiting_check', ...stamp('asha') }));
  });

  test('needsCheck false: Done stays done, awaiting_check is refused', async () => {
    await assertFails(updateDoc(taskRef('asha', 'normal'), { status: 'awaiting_check', ...stamp('asha') }));
    await assertSucceeds(updateDoc(taskRef('asha', 'normal'), { status: 'done', ...stamp('asha') }));
  });

  test('only an assignee moves to awaiting_check; a shared all-mode task cannot be finished by one person', async () => {
    await assertFails(updateDoc(taskRef('john', 'checked'), { status: 'awaiting_check', ...stamp('john') }));
    await assertFails(updateDoc(taskRef('baraka', 'shared'), { status: 'awaiting_check', ...stamp('baraka') }));
  });

  test('an assignee cannot leave awaiting_check or add completions while waiting', async () => {
    await assertFails(updateDoc(taskRef('asha', 'awaiting'), { status: 'done', ...stamp('asha') }));
    await assertFails(updateDoc(taskRef('asha', 'awaiting'), { status: 'in_progress', ...stamp('asha') }));
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), `orgs/${ORG}/tasks/sharedAwaiting`), { completedByIds: ['baraka'] });
    });
    await assertFails(updateDoc(taskRef('asha', 'sharedAwaiting'), { completedByIds: ['baraka', 'asha'], ...stamp('asha') }));
  });
});

describe('D-06: the creator confirms or returns', () => {
  test('the creator confirms awaiting_check -> done', async () => {
    await assertSucceeds(updateDoc(taskRef('john', 'awaiting'), { status: 'done', ...stamp('john') }));
  });

  test.each([
    ['the assignee', 'asha'],
    ['a manager above the assignee', 'neema'],
    ['a verified admin', 'idrisa'],
  ] as const)('%s cannot confirm', async (_label, who) => {
    await assertFails(updateDoc(taskRef(who, 'awaiting'), { status: 'done', ...stamp(who) }));
  });

  test('a return needs a non-empty reason (1-1000 characters)', async () => {
    await assertFails(updateDoc(taskRef('john', 'awaiting'), { status: 'in_progress', ...stamp('john') }));
    await assertFails(updateDoc(taskRef('john', 'awaiting'), { status: 'in_progress', returnReason: '   ', ...stamp('john') }));
    await assertFails(updateDoc(taskRef('john', 'awaiting'), { status: 'in_progress', returnReason: 'x'.repeat(1001), ...stamp('john') }));
    await assertSucceeds(updateDoc(taskRef('john', 'awaiting'), { status: 'in_progress', returnReason: 'Totals are wrong', ...stamp('john') }));
  });

  test('only the creator returns, only to in_progress, and nothing else changes', async () => {
    await assertFails(updateDoc(taskRef('asha', 'awaiting'), { status: 'in_progress', returnReason: 'redo', ...stamp('asha') }));
    await assertFails(updateDoc(taskRef('neema', 'awaiting'), { status: 'in_progress', returnReason: 'redo', ...stamp('neema') }));
    await assertFails(updateDoc(taskRef('john', 'awaiting'), { status: 'todo', returnReason: 'redo', ...stamp('john') }));
    await assertFails(updateDoc(taskRef('grace', 'sharedAwaiting'), { status: 'in_progress', returnReason: 'redo', completedByIds: [], ...stamp('grace') }));
    await assertSucceeds(updateDoc(taskRef('grace', 'sharedAwaiting'), { status: 'in_progress', returnReason: 'redo', ...stamp('grace') }));
  });

  test('confirm and return need awaiting_check; returnReason is not set any other way', async () => {
    await assertFails(updateDoc(taskRef('john', 'checked'), { status: 'done', ...stamp('john') }));
    await assertFails(updateDoc(taskRef('john', 'finished'), { status: 'in_progress', returnReason: 'redo', ...stamp('john') }));
    await assertFails(updateDoc(taskRef('john', 'normal'), { returnReason: 'redo', ...stamp('john') }));
    await assertFails(updateDoc(taskRef('asha', 'normal'), { status: 'in_progress', returnReason: 'x', ...stamp('asha') }));
  });

  test('awaiting_check counts as open: the creator edits and cancels it', async () => {
    await assertSucceeds(updateDoc(taskRef('john', 'awaiting'), { priority: 'urgent', ...stamp('john') }));
    await assertFails(updateDoc(taskRef('john', 'awaiting'), { status: 'cancelled', ...stamp('john') }));
    await assertSucceeds(updateDoc(taskRef('john', 'awaiting'), { status: 'cancelled', cancelReason: 'Not needed', ...stamp('john') }));
  });

  test('workflow tasks are untouched: no awaiting_check, no creator check', async () => {
    await assertFails(updateDoc(taskRef('asha', 'workflowChecked'), { status: 'awaiting_check', ...stamp('asha') }));
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), `orgs/${ORG}/tasks/workflowChecked`), { status: 'awaiting_check' });
    });
    await assertFails(updateDoc(taskRef('baraka', 'workflowChecked'), { status: 'done', ...stamp('baraka') }));
    await assertFails(updateDoc(taskRef('baraka', 'workflowChecked'), { status: 'in_progress', returnReason: 'redo', ...stamp('baraka') }));
  });
});

describe('needsCheck edits', () => {
  test('the creator changes needsCheck while the task is open', async () => {
    await assertSucceeds(updateDoc(taskRef('john', 'normal'), { needsCheck: true, ...stamp('john') }));
    await assertFails(updateDoc(taskRef('john', 'normal'), { needsCheck: 'yes', ...stamp('john') }));
  });

  test('not after it is finished, and not by anyone else', async () => {
    await assertFails(updateDoc(taskRef('john', 'finished'), { needsCheck: true, ...stamp('john') }));
    await assertFails(updateDoc(taskRef('asha', 'checked'), { needsCheck: false, ...stamp('asha') }));
    await assertFails(updateDoc(taskRef('neema', 'checked'), { needsCheck: false, ...stamp('neema') }));
  });
});

describe('server-only fields stay server-only', () => {
  test.each([
    ['assignmentError', { assignmentError: 'x' }],
    ['viewerIds', { viewerIds: ['asha', 'john', 'neema', 'baraka'] }],
    ['reassignmentNeeded', { reassignmentNeeded: true }],
    ['completedByIds with a status', { status: 'done', completedByIds: ['asha'] }],
    ['deleted back to false', { deleted: false, deletedAt: serverTimestamp() }],
  ])('%s cannot be written by the creator, assignee or admin', async (_label, change) => {
    for (const who of ['asha', 'john', 'idrisa'] as const) {
      await assertFails(updateDoc(taskRef(who, 'checked'), { ...change, ...stamp(who) }));
    }
  });
});

describe('A-01: resubmitting and discarding unassigned tasks', () => {
  const resubmit = (more: Record<string, unknown> = {}) => ({
    title: 'Fixed title', assigneeIds: ['asha'], assignmentState: 'pending', assignmentError: deleteField(), ...stamp('asha'), ...more,
  });

  test('the creator resubmits a rejected task for a new check', async () => {
    await assertSucceeds(updateDoc(taskRef('asha', 'rejected'), resubmit({
      description: 'More detail', priority: 'low', deadline: inDays(3), completionMode: 'any', needsCheck: true,
    })));
  });

  test.each([
    ['keeping the refusal code', { assignmentError: 'assignee-not-allowed' }],
    ['staying rejected', { assignmentState: 'rejected' }],
    ['jumping to assigned', { assignmentState: 'assigned' }],
    ['widening viewerIds', { viewerIds: ['asha', 'john'] }],
    ['changing status', { status: 'in_progress' }],
    ['changing confidential', { confidential: true }],
    ['changing the department', { deptId: 'OPS' }],
    ['changing participants', { participantIds: ['john'] }],
    ['no assignees', { assigneeIds: [] }],
    ['an empty title', { title: ' ' }],
  ])('a resubmission is refused when %s', async (_label, more) => {
    await assertFails(updateDoc(taskRef('asha', 'rejected'), resubmit(more)));
  });

  test('only the creator resubmits, and only a rejected task', async () => {
    await assertFails(updateDoc(taskRef('idrisa', 'rejected'), { ...resubmit(), ...stamp('idrisa') }));
    await assertFails(updateDoc(taskRef('asha', 'pending'), resubmit()));
    await assertFails(updateDoc(taskRef('john', 'normal'), { ...resubmit(), assigneeIds: ['asha'], ...stamp('john') }));
  });

  test('a rejected or pending task cannot be edited, moved or completed like an assigned one', async () => {
    await assertFails(updateDoc(taskRef('asha', 'rejected'), { title: 'x', ...stamp('asha') }));
    await assertFails(updateDoc(taskRef('asha', 'pending'), { status: 'in_progress', ...stamp('asha') }));
    await assertFails(updateDoc(taskRef('asha', 'pending'), { completedByIds: ['asha'], ...stamp('asha') }));
  });

  test('the creator discards a pending or rejected task', async () => {
    const discard = { deleted: true, deletedAt: serverTimestamp(), ...stamp('asha') };
    await assertSucceeds(updateDoc(taskRef('asha', 'rejected'), discard));
    await assertSucceeds(updateDoc(taskRef('asha', 'pending'), discard));
  });

  test('nobody else discards, and the discard path does not apply to assigned tasks', async () => {
    await assertFails(updateDoc(taskRef('idrisa', 'rejected', { adminVerified: false }), { deleted: true, deletedAt: serverTimestamp(), ...stamp('idrisa') }));
    await assertFails(updateDoc(taskRef('john', 'rejected'), { deleted: true, deletedAt: serverTimestamp(), ...stamp('john') }));
    // Asha is the assignee of 'normal', not its creator; staff never soft-delete assigned tasks.
    await assertFails(updateDoc(taskRef('asha', 'normal'), { deleted: true, deletedAt: serverTimestamp(), ...stamp('asha') }));
    await assertFails(updateDoc(taskRef('asha', 'rejected'), { deleted: true, deletedAt: minutesAgo(5), ...stamp('asha') }));
  });
});

describe('reading tasks (Sprint 2 branches)', () => {
  test('an assignee reads an assigned task even before viewerIds include them', async () => {
    await assertSucceeds(getDoc(taskRef('baraka', 'assignedNotViewer')));
  });

  test('an assignee cannot read a task that is not assigned yet', async () => {
    await assertFails(getDoc(taskRef('baraka', 'pendingForBaraka')));
    await assertFails(getDoc(taskRef('john', 'rejected')));
    await assertSucceeds(getDoc(taskRef('asha', 'rejected')));
  });

  test('a task without the deleted field is unreadable', async () => {
    await assertFails(getDoc(taskRef('asha', 'noDeletedField')));
  });

  test('a confidential task is not opened up by the assignee branch', async () => {
    await assertFails(getDoc(taskRef('asha', 'conf')));
    await assertSucceeds(getDoc(taskRef('rehema', 'conf')));
  });
});

describe('the app\'s list queries', () => {
  const tasksCol = (who: Who, opts: Parameters<typeof as>[2] = {}) => collection(db(who, opts), `orgs/${ORG}/tasks`);
  const auditCol = (who: Who, opts: Parameters<typeof as>[2] = {}) => collection(db(who, opts), `orgs/${ORG}/audit`);
  const OPEN = ['todo', 'in_progress', 'blocked', 'awaiting_check'];

  const myTasks = (who: Who, me: string) => query(tasksCol(who), where('assigneeIds', 'array-contains', me),
    where('assignmentState', '==', 'assigned'), where('deleted', '==', false), where('status', 'in', OPEN), orderBy('deadline'), limit(20));

  test('(a) My Tasks: allowed for me, refused for someone else\'s tasks', async () => {
    await assertSucceeds(getDocs(myTasks('asha', 'asha')));
    await assertSucceeds(getDocs(myTasks('baraka', 'baraka')));
    await assertFails(getDocs(myTasks('baraka', 'asha')));
    // Without the assignmentState filter the rules cannot prove the read.
    await assertFails(getDocs(query(tasksCol('asha'), where('assigneeIds', 'array-contains', 'asha'), where('deleted', '==', false), orderBy('deadline'), limit(20))));
    // Without deleted == false neither.
    await assertFails(getDocs(query(tasksCol('asha'), where('assigneeIds', 'array-contains', 'asha'), where('assignmentState', '==', 'assigned'), orderBy('deadline'), limit(20))));
  });

  test('(b) Team: viewerIds array-contains me with optional status and priority filters', async () => {
    const team = (who: Who, me: string, ...more: ReturnType<typeof where>[]) =>
      query(tasksCol(who), where('viewerIds', 'array-contains', me), where('deleted', '==', false), ...more, orderBy('deadline'), limit(20));
    await assertSucceeds(getDocs(team('john', 'john')));
    await assertSucceeds(getDocs(team('john', 'john', where('status', '==', 'in_progress'))));
    await assertSucceeds(getDocs(team('neema', 'neema', where('status', '==', 'todo'), where('priority', '==', 'high'))));
    await assertFails(getDocs(team('john', 'neema')));
  });

  test('(c) verified admin: every non-confidential task; refused unverified or for non-admins', async () => {
    const all = (who: Who, opts: Parameters<typeof as>[2] = {}) =>
      query(tasksCol(who, opts), where('deleted', '==', false), where('confidential', '==', false), orderBy('deadline'), limit(20));
    await assertSucceeds(getDocs(all('idrisa')));
    await assertFails(getDocs(all('idrisa', { adminVerified: false })));
    await assertFails(getDocs(all('john')));
  });

  test('(d) not yet assigned: my pending and rejected tasks', async () => {
    const mine = (who: Who, me: string) => query(tasksCol(who), where('viewerIds', 'array-contains', me), where('creatorId', '==', me),
      where('assignmentState', 'in', ['pending', 'rejected']), where('deleted', '==', false), limit(20));
    const snap = await assertSucceeds(getDocs(mine('asha', 'asha')));
    expect(snap.docs.map((d) => d.id).sort()).toEqual(['pending', 'rejected']);
    await assertFails(getDocs(mine('john', 'asha')));
  });

  test('(e) audit entries of a task: viewers, and verified admins for non-confidential entries', async () => {
    await assertSucceeds(getDocs(query(auditCol('asha'), where('taskId', '==', 'normal'), where('viewerIds', 'array-contains', 'asha'), limit(20))));
    await assertFails(getDocs(query(auditCol('baraka'), where('taskId', '==', 'normal'), limit(20))));
    await assertFails(getDocs(query(auditCol('baraka'), where('taskId', '==', 'normal'), where('viewerIds', 'array-contains', 'asha'), limit(20))));
    const admin = (who: Who, opts: Parameters<typeof as>[2] = {}) =>
      query(auditCol(who, opts), where('taskId', '==', 'normal'), where('confidential', '==', false), limit(20));
    await assertSucceeds(getDocs(admin('idrisa')));
    await assertFails(getDocs(admin('idrisa', { adminVerified: false })));
    await assertFails(getDocs(admin('john')));
    // CRITICAL: an admin query that does not filter on confidential must not return confidential entries.
    await assertFails(getDocs(query(auditCol('idrisa'), where('taskId', '==', 'conf'), limit(20))));
    await assertFails(getDocs(query(auditCol('idrisa'), limit(20))));
  });
});
