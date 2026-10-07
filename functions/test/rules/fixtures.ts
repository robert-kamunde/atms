/**
 * Shared fixtures for the Security Rules tests. The organisation mirrors the clickable
 * prototype (docs/PRODUCT_SPEC.md section 10) so the same people appear in every test.
 */
import { readFileSync } from 'fs';
import { resolve } from 'path';
import {
  initializeTestEnvironment,
  RulesTestEnvironment,
  RulesTestContext,
} from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp } from 'firebase/firestore';

export const ORG = 'org1';
export const OTHER_ORG = 'org2';

const nowSec = () => Math.floor(Date.now() / 1000);
const DAY = 86400;

export interface Person {
  uid: string;
  role: 'admin' | 'manager' | 'staff';
  deptId: string;
  supervisorId: string | null;
  managerChain: string[];
  confidentialDepts: string[];
  active?: boolean;
  org?: string;
}

export const people: Record<string, Person> = {
  neema: { uid: 'neema', role: 'manager', deptId: 'MGT', supervisorId: null, managerChain: [], confidentialDepts: ['HR', 'FIN'] },
  john: { uid: 'john', role: 'manager', deptId: 'FIN', supervisorId: 'neema', managerChain: ['neema'], confidentialDepts: [] },
  asha: { uid: 'asha', role: 'staff', deptId: 'FIN', supervisorId: 'john', managerChain: ['john', 'neema'], confidentialDepts: [] },
  grace: { uid: 'grace', role: 'manager', deptId: 'OPS', supervisorId: 'neema', managerChain: ['neema'], confidentialDepts: [] },
  baraka: { uid: 'baraka', role: 'staff', deptId: 'OPS', supervisorId: 'grace', managerChain: ['grace', 'neema'], confidentialDepts: [] },
  rehema: { uid: 'rehema', role: 'staff', deptId: 'HR', supervisorId: 'neema', managerChain: ['neema'], confidentialDepts: ['HR'] },
  idrisa: { uid: 'idrisa', role: 'admin', deptId: 'ICT', supervisorId: 'neema', managerChain: ['neema'], confidentialDepts: [] },
  gone: { uid: 'gone', role: 'staff', deptId: 'FIN', supervisorId: 'john', managerChain: ['john', 'neema'], confidentialDepts: [], active: false },
  outsider: { uid: 'outsider', role: 'admin', deptId: 'X', supervisorId: null, managerChain: [], confidentialDepts: [], org: OTHER_ORG },
};

export async function makeEnv(): Promise<RulesTestEnvironment> {
  const root = resolve(__dirname, '../../..');
  return initializeTestEnvironment({
    projectId: 'demo-atms',
    firestore: { rules: readFileSync(resolve(root, 'firestore.rules'), 'utf8'), host: '127.0.0.1', port: 8080 },
    storage: { rules: readFileSync(resolve(root, 'storage.rules'), 'utf8'), host: '127.0.0.1', port: 9199 },
  });
}

interface AsOptions {
  /** Days since the person last really signed in (default 0). */
  signedInDaysAgo?: number;
  /** Admin second factor verified (default true for admins). */
  adminVerified?: boolean;
  /** Override the orgId claim. */
  orgClaim?: string;
}

/** A signed-in context with the claims Cloud Functions would set. */
export function as(env: RulesTestEnvironment, name: keyof typeof people, opts: AsOptions = {}): RulesTestContext {
  const p = people[name];
  const claims: Record<string, unknown> = {
    orgId: opts.orgClaim ?? p.org ?? ORG,
    auth_time: nowSec() - (opts.signedInDaysAgo ?? 0) * DAY,
  };
  const verified = opts.adminVerified ?? p.role === 'admin';
  if (verified) claims.adminVerifiedUntil = nowSec() + 7 * DAY;
  return env.authenticatedContext(p.uid, claims);
}

export const minutesAgo = (m: number) => Timestamp.fromMillis(Date.now() - m * 60_000);
export const inDays = (d: number) => Timestamp.fromMillis(Date.now() + d * DAY * 1000);

export const tasks = {
  // Simple Finance task: John asked Asha; visible to Asha and her manager chain.
  normal: {
    title: 'Prepare Q3 budget summary', description: '', priority: 'high', status: 'todo',
    deadline: inDays(2), creatorId: 'john', assigneeIds: ['asha'], deptId: 'FIN', confidential: false,
    participantIds: [], viewerIds: ['asha', 'john', 'neema'], templateId: null, completionMode: 'all',
    completedByIds: [], assignmentState: 'assigned', escalationLevel: 0, overdue: false,
    createdAt: minutesAgo(60), updatedAt: minutesAgo(60), updatedBy: 'john',
  },
  // Confidential HR task: only Rehema (participant) and holders of HR confidential access.
  conf: {
    title: 'Disciplinary case: staff member X', description: 'secret', priority: 'urgent', status: 'in_progress',
    deadline: inDays(1), creatorId: 'rehema', assigneeIds: ['rehema'], deptId: 'HR', confidential: true,
    participantIds: ['rehema'], viewerIds: ['rehema'], templateId: null, completionMode: 'all',
    completedByIds: [], assignmentState: 'assigned', escalationLevel: 0, overdue: false,
    createdAt: minutesAgo(60), updatedAt: minutesAgo(60), updatedBy: 'rehema',
  },
  // Workflow task at step 3 (Finance check), owned by Asha.
  workflow: {
    title: 'Purchase 5 laptops', description: '', priority: 'high', status: 'in_progress',
    deadline: inDays(5), creatorId: 'baraka', assigneeIds: ['asha'], deptId: 'OPS', confidential: false,
    participantIds: [], viewerIds: ['baraka', 'grace', 'neema', 'asha', 'john'], templateId: 'purchase',
    templateVersion: 1, currentStep: 3, stepDeadline: inDays(1), completionMode: 'all', completedByIds: [],
    assignmentState: 'assigned', escalationLevel: 0, overdue: false,
    createdAt: minutesAgo(600), updatedAt: minutesAgo(60), updatedBy: 'system',
  },
  // Two assignees who must both finish.
  shared: {
    title: 'Stock count', description: '', priority: 'medium', status: 'in_progress',
    deadline: inDays(3), creatorId: 'grace', assigneeIds: ['baraka', 'asha'], deptId: 'OPS', confidential: false,
    participantIds: [], viewerIds: ['baraka', 'asha', 'grace', 'neema', 'john'], templateId: null, completionMode: 'all',
    completedByIds: [], assignmentState: 'assigned', escalationLevel: 0, overdue: false,
    createdAt: minutesAgo(60), updatedAt: minutesAgo(60), updatedBy: 'grace',
  },
};

/** Seeds the organisation with rules disabled, as Cloud Functions would write it. */
export async function seed(env: RulesTestEnvironment): Promise<void> {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, `orgs/${ORG}`), {
      name: 'Demo Org', timezone: 'Africa/Dar_es_Salaam', workingHoursEnabled: false,
      reminderHours: [24, 1], escalationHours: 24, escalationMaxLevel: 2, smsEnabled: true, smsMonthlyCap: 50000,
      auditRetentionYears: 3,
    });
    await setDoc(doc(db, `orgs/${OTHER_ORG}`), { name: 'Other Org' });
    await setDoc(doc(db, `orgs/${ORG}/departments/FIN`), { name: 'Finance', headUserId: 'john', active: true });
    for (const p of Object.values(people)) {
      const org = p.org ?? ORG;
      await setDoc(doc(db, `orgs/${org}/users/${p.uid}`), {
        name: p.uid, role: p.role, deptId: p.deptId, supervisorId: p.supervisorId, managerChain: p.managerChain,
        confidentialDepts: p.confidentialDepts, language: 'en', active: p.active ?? true,
      });
      await setDoc(doc(db, `orgs/${org}/users/${p.uid}/private/contact`), { phone: '+2557000000' + p.uid.length, email: null });
    }
    for (const [id, t] of Object.entries(tasks)) {
      await setDoc(doc(db, `orgs/${ORG}/tasks/${id}`), t);
    }
    await setDoc(doc(db, `orgs/${ORG}/tasks/normal/comments/fresh`), { authorId: 'asha', text: 'On it', mentions: [], createdAt: minutesAgo(5), removed: false });
    await setDoc(doc(db, `orgs/${ORG}/tasks/normal/comments/old`), { authorId: 'asha', text: 'Old note', mentions: [], createdAt: minutesAgo(20), removed: false });
    await setDoc(doc(db, `orgs/${ORG}/tasks/conf/comments/c1`), { authorId: 'rehema', text: 'Hearing on Friday', mentions: [], createdAt: minutesAgo(5), removed: false });
    await setDoc(doc(db, `orgs/${ORG}/audit/a-normal`), { taskId: 'normal', actorId: 'john', action: 'task_created', viewerIds: tasks.normal.viewerIds, confidential: false });
    await setDoc(doc(db, `orgs/${ORG}/audit/a-conf`), { taskId: 'conf', actorId: 'rehema', action: 'task_created', viewerIds: ['rehema'], confidential: true });
    await setDoc(doc(db, `orgs/${ORG}/notifications/n-asha`), { userId: 'asha', type: 'assigned', taskId: 'normal', text: 'New task', read: false });
    await setDoc(doc(db, `orgs/${ORG}/stats/user_asha_2026-10-07`), { scope: 'user', scopeId: 'asha', date: '2026-10-07', created: 1 });
    await setDoc(doc(db, `orgs/${ORG}/stats/org_${ORG}_2026-10-07`), { scope: 'org', scopeId: ORG, date: '2026-10-07', created: 9 });
    await setDoc(doc(db, `orgs/${ORG}/templates/purchase`), { name: 'Purchase request', version: 1, active: true, steps: [] });
  });
}
