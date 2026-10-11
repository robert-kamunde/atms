/**
 * Firestore Security Rules tests (PDD 4.8, 4.11, section 6; master instructions "Security tests").
 * Every role tries to read and write every kind of document, allowed and denied.
 * Run with: npm run test:rules (starts the Firestore and Storage emulators).
 */
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import {
  addDoc, collection, deleteDoc, doc, getDoc, getDocs, query, serverTimestamp, setDoc, updateDoc, where, limit,
} from 'firebase/firestore';
import { as, inDays, makeEnv, ORG, seed, tasks } from './fixtures';

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await makeEnv();
});
afterAll(async () => {
  await env.cleanup();
});
beforeEach(async () => {
  await env.clearFirestore();
  await seed(env);
});

const taskRef = (db: ReturnType<ReturnType<typeof as>['firestore']>, id: string) => doc(db, `orgs/${ORG}/tasks/${id}`);
const stamp = (uid: string) => ({ updatedAt: serverTimestamp(), updatedBy: uid });

const newTask = (uid: string, extra: Record<string, unknown> = {}) => ({
  title: 'Collect receipts', description: '', priority: 'medium', deadline: inDays(1), assigneeIds: [uid],
  deptId: 'FIN', confidential: false, participantIds: [], templateId: null, completionMode: 'all',
  creatorId: uid, status: 'todo', viewerIds: [uid], assignmentState: 'pending', completedByIds: [],
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), updatedBy: uid, ...extra,
});

describe('who can read a task', () => {
  test.each([
    ['asha (assignee)', 'asha'],
    ['john (creator, her manager)', 'john'],
    ['neema (top of the chain)', 'neema'],
    ['idrisa (verified admin)', 'idrisa'],
  ] as const)('%s can read the normal task', async (_label, who) => {
    await assertSucceeds(getDoc(taskRef(as(env, who).firestore(), 'normal')));
  });

  test.each([
    ['baraka (other department)', 'baraka'],
    ['grace (manager of another team)', 'grace'],
    ['rehema (HR staff)', 'rehema'],
  ] as const)('%s cannot read the normal task', async (_label, who) => {
    await assertFails(getDoc(taskRef(as(env, who).firestore(), 'normal')));
  });

  test('an admin without the second factor cannot use admin visibility', async () => {
    await assertFails(getDoc(taskRef(as(env, 'idrisa', { adminVerified: false }).firestore(), 'normal')));
  });

  test('signed-out users, other organisations and deactivated users are refused', async () => {
    await assertFails(getDoc(taskRef(env.unauthenticatedContext().firestore(), 'normal')));
    await assertFails(getDoc(taskRef(as(env, 'outsider').firestore(), 'normal')));
    await assertFails(getDoc(taskRef(as(env, 'outsider', { orgClaim: ORG }).firestore(), 'normal')));
    await assertFails(getDoc(taskRef(as(env, 'gone').firestore(), 'normal')));
  });

  test('sessions expire after 30 days for staff and 7 days for admins', async () => {
    await assertSucceeds(getDoc(taskRef(as(env, 'asha', { signedInDaysAgo: 29 }).firestore(), 'normal')));
    await assertFails(getDoc(taskRef(as(env, 'asha', { signedInDaysAgo: 31 }).firestore(), 'normal')));
    await assertSucceeds(getDoc(taskRef(as(env, 'idrisa', { signedInDaysAgo: 6 }).firestore(), 'normal')));
    await assertFails(getDoc(taskRef(as(env, 'idrisa', { signedInDaysAgo: 8 }).firestore(), 'normal')));
  });

  test('lists must be limited to tasks the reader may see', async () => {
    const db = as(env, 'asha').firestore();
    const tasksCol = collection(db, `orgs/${ORG}/tasks`);
    await assertSucceeds(getDocs(query(tasksCol, where('viewerIds', 'array-contains', 'asha'), limit(20))));
    await assertFails(getDocs(query(tasksCol, limit(20))));
    await assertFails(getDocs(query(tasksCol, where('deptId', '==', 'FIN'), limit(20))));
  });

  test('a verified admin can list non-confidential tasks but not all tasks', async () => {
    const tasksCol = collection(as(env, 'idrisa').firestore(), `orgs/${ORG}/tasks`);
    await assertSucceeds(getDocs(query(tasksCol, where('confidential', '==', false), limit(20))));
    await assertFails(getDocs(query(tasksCol, limit(20))));
  });
});

describe('CRITICAL: confidential tasks', () => {
  test('participants and holders of confidential access for the department can read', async () => {
    await assertSucceeds(getDoc(taskRef(as(env, 'rehema').firestore(), 'conf')));
    await assertSucceeds(getDoc(taskRef(as(env, 'neema').firestore(), 'conf')));
  });

  test.each(['asha', 'john', 'grace', 'baraka', 'idrisa', 'outsider', 'gone'] as const)(
    'a direct read by %s (modified client) is rejected', async (who) => {
      await assertFails(getDoc(taskRef(as(env, who).firestore(), 'conf')));
    });

  test('querying for confidential tasks without access is rejected', async () => {
    const tasksCol = collection(as(env, 'grace').firestore(), `orgs/${ORG}/tasks`);
    await assertFails(getDocs(query(tasksCol, where('confidential', '==', true), limit(20))));
    await assertFails(getDocs(query(tasksCol, where('deptId', '==', 'HR'), where('confidential', '==', true), limit(20))));
    const adminCol = collection(as(env, 'idrisa').firestore(), `orgs/${ORG}/tasks`);
    await assertFails(getDocs(query(adminCol, where('confidential', '==', true), limit(20))));
  });

  test('a holder of HR confidential access can list HR confidential tasks', async () => {
    const tasksCol = collection(as(env, 'neema').firestore(), `orgs/${ORG}/tasks`);
    await assertSucceeds(getDocs(query(tasksCol, where('deptId', '==', 'HR'), where('confidential', '==', true), limit(20))));
  });

  test('comments and attachments of a confidential task are protected the same way', async () => {
    await assertFails(getDoc(doc(as(env, 'idrisa').firestore(), `orgs/${ORG}/tasks/conf/comments/c1`)));
    await assertFails(getDocs(collection(as(env, 'asha').firestore(), `orgs/${ORG}/tasks/conf/comments`)));
    await assertFails(getDocs(collection(as(env, 'asha').firestore(), `orgs/${ORG}/tasks/conf/attachments`)));
    await assertSucceeds(getDoc(doc(as(env, 'rehema').firestore(), `orgs/${ORG}/tasks/conf/comments/c1`)));
  });

  test('a mention never grants access: an outsider cannot comment on a confidential task', async () => {
    await assertFails(addDoc(collection(as(env, 'asha').firestore(), `orgs/${ORG}/tasks/conf/comments`),
      { authorId: 'asha', text: 'hi', mentions: [], createdAt: serverTimestamp(), removed: false }));
  });

  test('the audit entry of a confidential task is hidden from admins', async () => {
    await assertFails(getDoc(doc(as(env, 'idrisa').firestore(), `orgs/${ORG}/audit/a-conf`)));
    await assertSucceeds(getDoc(doc(as(env, 'rehema').firestore(), `orgs/${ORG}/audit/a-conf`)));
  });

  test('only people with confidential access can create a confidential task', async () => {
    const t = (uid: string, dept: string) => newTask(uid, { confidential: true, deptId: dept });
    await assertSucceeds(addDoc(collection(as(env, 'rehema').firestore(), `orgs/${ORG}/tasks`), t('rehema', 'HR')));
    await assertFails(addDoc(collection(as(env, 'asha').firestore(), `orgs/${ORG}/tasks`), t('asha', 'FIN')));
    await assertFails(addDoc(collection(as(env, 'rehema').firestore(), `orgs/${ORG}/tasks`), t('rehema', 'FIN')));
  });
});

describe('creating tasks', () => {
  const tasksCol = (who: Parameters<typeof as>[1]) => collection(as(env, who).firestore(), `orgs/${ORG}/tasks`);

  test('a member can create a pending task for the server to assign', async () => {
    await assertSucceeds(addDoc(tasksCol('asha'), newTask('asha')));
    await assertSucceeds(addDoc(tasksCol('john'), newTask('john', { assigneeIds: ['asha'], templateId: 'purchase' })));
  });

  test.each([
    ['extra viewers', { viewerIds: ['asha', 'baraka'] }],
    ['already assigned', { assignmentState: 'assigned' }],
    ['status done', { status: 'done' }],
    ['a workflow step', { currentStep: 2 }],
    ['an escalation level', { escalationLevel: 2 }],
    ['marked overdue', { overdue: true }],
    ['a pinned template version', { templateVersion: 1 }],
    ['someone else as creator', { creatorId: 'john' }],
    ['no title', { title: '  ' }],
    ['a bad priority', { priority: 'critical' }],
    ['no assignee', { assigneeIds: [] }],
    ['a client clock createdAt', { createdAt: inDays(0) }],
    ['a bad completion mode', { completionMode: 'some' }],
    ['a reassignment flag (server-only)', { reassignmentNeeded: true }],
    ['a reassignment reason (server-only)', { reassignmentReason: 'user_deactivated' }],
  ])('is refused with %s', async (_label, extra) => {
    await assertFails(addDoc(tasksCol('asha'), newTask('asha', extra)));
  });

  test('a deactivated user cannot create tasks', async () => {
    await assertFails(addDoc(tasksCol('gone'), newTask('gone')));
  });
});

describe('updating tasks', () => {
  test('the assignee moves a simple task through its statuses', async () => {
    const ref = taskRef(as(env, 'asha').firestore(), 'normal');
    await assertSucceeds(updateDoc(ref, { status: 'in_progress', ...stamp('asha') }));
    await assertFails(updateDoc(ref, { status: 'blocked', ...stamp('asha') }));
    await assertSucceeds(updateDoc(ref, { status: 'blocked', blockedReason: 'Waiting for invoices', ...stamp('asha') }));
    await assertSucceeds(updateDoc(ref, { status: 'in_progress', ...stamp('asha') }));
    await assertSucceeds(updateDoc(ref, { status: 'done', ...stamp('asha') }));
  });

  test('updatedBy must be the writer and updatedAt the server time', async () => {
    const ref = taskRef(as(env, 'asha').firestore(), 'normal');
    await assertFails(updateDoc(ref, { status: 'in_progress', updatedAt: serverTimestamp(), updatedBy: 'john' }));
    await assertFails(updateDoc(ref, { status: 'in_progress', updatedAt: inDays(0), updatedBy: 'asha' }));
  });

  test.each([
    ['viewerIds', { viewerIds: ['asha', 'baraka'] }],
    ['currentStep', { currentStep: 5 }],
    ['escalationLevel', { escalationLevel: 1 }],
    ['overdue', { overdue: true }],
    ['assigneeIds (reassign is server-only)', { assigneeIds: ['baraka'] }],
    ['confidential', { confidential: true }],
    ['deptId', { deptId: 'OPS' }],
    ['creatorId', { creatorId: 'asha' }],
    ['assignmentState', { assignmentState: 'pending' }],
    ['reassignmentNeeded (server-only)', { reassignmentNeeded: true }],
    ['reassignmentReason (server-only)', { reassignmentReason: 'user_deactivated' }],
  ])('nobody can change %s from the app', async (_label, change) => {
    await assertFails(updateDoc(taskRef(as(env, 'asha').firestore(), 'normal'), { ...change, ...stamp('asha') }));
    await assertFails(updateDoc(taskRef(as(env, 'john').firestore(), 'normal'), { ...change, ...stamp('john') }));
    await assertFails(updateDoc(taskRef(as(env, 'idrisa').firestore(), 'normal'), { ...change, ...stamp('idrisa') }));
  });

  test('workflow status and step can only be changed by the server', async () => {
    const ref = taskRef(as(env, 'asha').firestore(), 'workflow');
    await assertFails(updateDoc(ref, { status: 'done', ...stamp('asha') }));
    await assertFails(updateDoc(ref, { currentStep: 4, ...stamp('asha') }));
    await assertFails(updateDoc(ref, { stepDeadline: inDays(9), ...stamp('asha') }));
    await assertFails(updateDoc(taskRef(as(env, 'baraka').firestore(), 'workflow'), { status: 'cancelled', cancelReason: 'x', ...stamp('baraka') }));
  });

  test('only the creator edits title, priority and deadline', async () => {
    await assertSucceeds(updateDoc(taskRef(as(env, 'john').firestore(), 'normal'), { deadline: inDays(4), priority: 'urgent', ...stamp('john') }));
    await assertFails(updateDoc(taskRef(as(env, 'asha').firestore(), 'normal'), { title: 'Renamed', ...stamp('asha') }));
    await assertFails(updateDoc(taskRef(as(env, 'neema').firestore(), 'normal'), { deadline: inDays(9), ...stamp('neema') }));
  });

  test('cancelling a simple task needs a reason and the creator or a manager', async () => {
    await assertFails(updateDoc(taskRef(as(env, 'john').firestore(), 'normal'), { status: 'cancelled', ...stamp('john') }));
    await assertFails(updateDoc(taskRef(as(env, 'asha').firestore(), 'normal'), { status: 'cancelled', cancelReason: 'no', ...stamp('asha') }));
    await assertSucceeds(updateDoc(taskRef(as(env, 'john').firestore(), 'normal'), { status: 'cancelled', cancelReason: 'Not needed', ...stamp('john') }));
  });

  test('with several assignees each adds only themselves, and nobody can mark it done alone', async () => {
    const ref = taskRef(as(env, 'baraka').firestore(), 'shared');
    await assertFails(updateDoc(ref, { status: 'done', ...stamp('baraka') }));
    await assertFails(updateDoc(ref, { completedByIds: ['baraka', 'asha'], ...stamp('baraka') }));
    await assertFails(updateDoc(ref, { completedByIds: ['asha'], ...stamp('baraka') }));
    await assertSucceeds(updateDoc(ref, { completedByIds: ['baraka'], ...stamp('baraka') }));
  });

  test('tasks are never hard-deleted; soft delete follows the permission matrix', async () => {
    await assertFails(deleteDoc(taskRef(as(env, 'idrisa').firestore(), 'normal')));
    await assertFails(deleteDoc(taskRef(as(env, 'john').firestore(), 'normal')));
    const soft = (uid: string) => ({ deleted: true, deletedAt: serverTimestamp(), ...stamp(uid) });
    await assertFails(updateDoc(taskRef(as(env, 'asha').firestore(), 'normal'), soft('asha')));
    await assertSucceeds(updateDoc(taskRef(as(env, 'john').firestore(), 'normal'), soft('john')));
    await assertFails(getDoc(taskRef(as(env, 'asha').firestore(), 'normal')));
  });

  test('a task flagged for reassignment keeps its flag until the server clears it', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), `orgs/${ORG}/tasks/normal`), { reassignmentNeeded: true, reassignmentReason: 'user_deactivated' });
    });
    const asha = taskRef(as(env, 'asha').firestore(), 'normal');
    await assertFails(updateDoc(asha, { reassignmentNeeded: false, ...stamp('asha') }));
    await assertFails(updateDoc(asha, { status: 'in_progress', reassignmentNeeded: false, ...stamp('asha') }));
    await assertFails(updateDoc(taskRef(as(env, 'john').firestore(), 'normal'), { priority: 'low', reassignmentReason: 'other', ...stamp('john') }));
    await assertFails(updateDoc(taskRef(as(env, 'idrisa').firestore(), 'normal'), { deleted: true, deletedAt: serverTimestamp(), reassignmentNeeded: false, ...stamp('idrisa') }));
    // Ordinary allowed changes still work and leave the flag alone.
    await assertSucceeds(updateDoc(asha, { status: 'in_progress', ...stamp('asha') }));
  });

  test('a user who cannot see a task cannot update it', async () => {
    await assertFails(updateDoc(taskRef(as(env, 'baraka').firestore(), 'normal'), { status: 'in_progress', ...stamp('baraka') }));
    await assertFails(updateDoc(taskRef(as(env, 'asha').firestore(), 'conf'), { status: 'done', ...stamp('asha') }));
  });
});

describe('workflow transition requests', () => {
  const reqCol = (who: Parameters<typeof as>[1]) => collection(as(env, who).firestore(), `orgs/${ORG}/transitionRequests`);
  const req = (uid: string, extra: Record<string, unknown> = {}) => ({
    taskId: 'workflow', fromStep: 3, action: 'approve', requestedBy: uid, createdAt: serverTimestamp(), ...extra,
  });

  test('a participant can ask to approve', async () => {
    await assertSucceeds(addDoc(reqCol('asha'), req('asha')));
  });

  test('reject and send back need a comment; send back needs a target step', async () => {
    await assertFails(addDoc(reqCol('asha'), req('asha', { action: 'reject' })));
    await assertSucceeds(addDoc(reqCol('asha'), req('asha', { action: 'reject', comment: 'Quote missing' })));
    await assertFails(addDoc(reqCol('asha'), req('asha', { action: 'sendBack', comment: 'Redo' })));
    await assertSucceeds(addDoc(reqCol('asha'), req('asha', { action: 'sendBack', comment: 'Redo', toStep: 1 })));
  });

  test.each([
    ['for someone else', { requestedBy: 'john' }],
    ['with a result filled in', { result: { status: 'applied' } }],
    ['with an unknown action', { action: 'escalate' }],
    ['for a task the user cannot see', { taskId: 'conf' }],
  ])('is refused when made %s', async (_label, extra) => {
    await assertFails(addDoc(reqCol('asha'), req('asha', extra)));
  });

  test('requests cannot be changed or deleted, and only the requester reads them', async () => {
    const db = as(env, 'asha').firestore();
    const ref = doc(db, `orgs/${ORG}/transitionRequests/r1`);
    await assertSucceeds(setDoc(ref, req('asha')));
    await assertFails(updateDoc(ref, { result: { status: 'applied' } }));
    await assertFails(deleteDoc(ref));
    await assertSucceeds(getDoc(ref));
    await assertFails(getDoc(doc(as(env, 'john').firestore(), `orgs/${ORG}/transitionRequests/r1`)));
  });
});

describe('comments', () => {
  const c = (who: Parameters<typeof as>[1], id: string) => doc(as(env, who).firestore(), `orgs/${ORG}/tasks/normal/comments/${id}`);

  test('a viewer comments; outsiders cannot', async () => {
    const body = (uid: string) => ({ authorId: uid, text: 'Done by Friday', mentions: ['john'], createdAt: serverTimestamp(), removed: false });
    await assertSucceeds(setDoc(c('john', 'new1'), body('john')));
    await assertFails(setDoc(c('baraka', 'new2'), body('baraka')));
    await assertFails(setDoc(c('asha', 'new3'), body('john')));
  });

  test('edits are allowed for 15 minutes, then locked', async () => {
    await assertSucceeds(updateDoc(c('asha', 'fresh'), { text: 'On it today', editedAt: serverTimestamp() }));
    await assertFails(updateDoc(c('asha', 'old'), { text: 'Changed later', editedAt: serverTimestamp() }));
    await assertFails(updateDoc(c('john', 'fresh'), { text: 'Not mine', editedAt: serverTimestamp() }));
  });

  test('removal leaves an empty "removed" comment; hard delete is refused', async () => {
    await assertFails(deleteDoc(c('asha', 'old')));
    await assertSucceeds(updateDoc(c('asha', 'old'), { removed: true, text: '', removedAt: serverTimestamp() }));
  });
});

describe('server-only collections', () => {
  test('nobody writes audit entries from the app, not even an admin', async () => {
    await assertFails(setDoc(doc(as(env, 'idrisa').firestore(), `orgs/${ORG}/audit/x`), { action: 'fake' }));
    await assertFails(updateDoc(doc(as(env, 'idrisa').firestore(), `orgs/${ORG}/audit/a-normal`), { action: 'edited' }));
    await assertFails(deleteDoc(doc(as(env, 'idrisa').firestore(), `orgs/${ORG}/audit/a-normal`)));
    await assertFails(updateDoc(doc(as(env, 'john').firestore(), `orgs/${ORG}/audit/a-normal`), { action: 'edited' }));
  });

  test('audit entries are readable by the task viewers and verified admins', async () => {
    await assertSucceeds(getDoc(doc(as(env, 'asha').firestore(), `orgs/${ORG}/audit/a-normal`)));
    await assertSucceeds(getDoc(doc(as(env, 'idrisa').firestore(), `orgs/${ORG}/audit/a-normal`)));
    await assertFails(getDoc(doc(as(env, 'baraka').firestore(), `orgs/${ORG}/audit/a-normal`)));
  });

  test('notifications: read and mark read only your own; never create', async () => {
    const mine = doc(as(env, 'asha').firestore(), `orgs/${ORG}/notifications/n-asha`);
    await assertSucceeds(getDoc(mine));
    await assertSucceeds(updateDoc(mine, { read: true }));
    await assertFails(updateDoc(mine, { text: 'changed' }));
    await assertFails(getDoc(doc(as(env, 'john').firestore(), `orgs/${ORG}/notifications/n-asha`)));
    await assertFails(setDoc(doc(as(env, 'asha').firestore(), `orgs/${ORG}/notifications/n2`), { userId: 'asha', read: false }));
  });

  test('counters: own stats only; organisation stats for verified admins', async () => {
    await assertSucceeds(getDoc(doc(as(env, 'asha').firestore(), `orgs/${ORG}/stats/user_asha_2026-10-07`)));
    await assertFails(getDoc(doc(as(env, 'baraka').firestore(), `orgs/${ORG}/stats/user_asha_2026-10-07`)));
    await assertSucceeds(getDoc(doc(as(env, 'idrisa').firestore(), `orgs/${ORG}/stats/org_${ORG}_2026-10-07`)));
    await assertFails(getDoc(doc(as(env, 'neema').firestore(), `orgs/${ORG}/stats/org_${ORG}_2026-10-07`)));
    await assertFails(setDoc(doc(as(env, 'idrisa').firestore(), `orgs/${ORG}/stats/x`), { scope: 'org' }));
  });

  test('templates are saved only through the server', async () => {
    await assertSucceeds(getDoc(doc(as(env, 'asha').firestore(), `orgs/${ORG}/templates/purchase`)));
    await assertFails(updateDoc(doc(as(env, 'idrisa').firestore(), `orgs/${ORG}/templates/purchase`), { version: 2 }));
  });

  test('second-factor codes are unreadable', async () => {
    await assertFails(getDoc(doc(as(env, 'idrisa').firestore(), `orgs/${ORG}/secure/adminCodes`)));
  });
});

describe('users and organisation', () => {
  test('people change only their own language, consent and comment muting', async () => {
    const mine = doc(as(env, 'asha').firestore(), `orgs/${ORG}/users/asha`);
    await assertSucceeds(updateDoc(mine, { language: 'sw' }));
    await assertFails(updateDoc(mine, { language: 'fr' }));
    await assertSucceeds(updateDoc(mine, { consentVersion: '2026-10', consentAcceptedAt: serverTimestamp() }));
    await assertFails(updateDoc(mine, { role: 'admin' }));
    await assertFails(updateDoc(mine, { confidentialDepts: ['HR'] }));
    await assertFails(updateDoc(mine, { supervisorId: null }));
    await assertFails(updateDoc(doc(as(env, 'asha').firestore(), `orgs/${ORG}/users/john`), { language: 'sw' }));
  });

  test('user records are created only by the server, even for admins', async () => {
    await assertFails(setDoc(doc(as(env, 'idrisa').firestore(), `orgs/${ORG}/users/newbie`), { role: 'staff', active: true }));
    await assertFails(updateDoc(doc(as(env, 'idrisa').firestore(), `orgs/${ORG}/users/asha`), { role: 'manager' }));
  });

  test('phone numbers are visible only to the person and verified admins', async () => {
    await assertSucceeds(getDoc(doc(as(env, 'asha').firestore(), `orgs/${ORG}/users/asha/private/contact`)));
    await assertFails(getDoc(doc(as(env, 'john').firestore(), `orgs/${ORG}/users/asha/private/contact`)));
    await assertSucceeds(getDoc(doc(as(env, 'idrisa').firestore(), `orgs/${ORG}/users/asha/private/contact`)));
    await assertFails(getDoc(doc(as(env, 'idrisa', { adminVerified: false }).firestore(), `orgs/${ORG}/users/asha/private/contact`)));
  });

  test('only a verified admin changes organisation settings, within limits', async () => {
    const orgDoc = (who: Parameters<typeof as>[1], v = {}) => doc(as(env, who, v).firestore(), `orgs/${ORG}`);
    await assertSucceeds(updateDoc(orgDoc('idrisa'), { smsMonthlyCap: 20000, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(orgDoc('idrisa', { adminVerified: false }), { smsMonthlyCap: 20000, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(orgDoc('neema'), { smsMonthlyCap: 20000, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(orgDoc('idrisa'), { auditRetentionYears: 1, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(orgDoc('idrisa'), { smsUsedThisMonth: 0, updatedAt: serverTimestamp() }));
  });

  test('departments: verified admins create and edit; nobody deletes', async () => {
    const d = (who: Parameters<typeof as>[1]) => doc(as(env, who).firestore(), `orgs/${ORG}/departments/LEGAL`);
    await assertFails(setDoc(d('neema'), { name: 'Legal', headUserId: null, active: true, createdAt: serverTimestamp() }));
    await assertSucceeds(setDoc(d('idrisa'), { name: 'Legal', headUserId: null, active: true, createdAt: serverTimestamp() }));
    await assertFails(deleteDoc(d('idrisa')));
  });

  test('the original fixture tasks are intact', () => {
    expect(tasks.conf.confidential).toBe(true);
  });
});
