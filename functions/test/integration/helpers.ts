/**
 * Shared set-up for the integration tests: the handlers run against the Auth and Firestore
 * emulators (npm run test:integration) with the MOCK SMS and e-mail providers and a test clock.
 */
import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import type { CallerAuth, Deps } from '../../src/auth/deps';
import { EmulatorEmailProvider } from '../../src/notifications/email/emulatorProvider';
import { EmulatorSmsProvider } from '../../src/notifications/sms/emulatorProvider';
import { AtmsError } from '../../src/shared/errors';

export const PROJECT = 'demo-atms';
export const ORG = 'org1';
export const OTHER_ORG = 'org2';
export const APP_URL = 'https://example.invalid/atms';

const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
if (!firestoreHost || !authHost) {
  // Never run these tests against a real project.
  throw new Error('Run with npm run test:integration (needs the Auth and Firestore emulators)');
}

if (getApps().length === 0) initializeApp({ projectId: PROJECT });
export const db = getFirestore();
export const auth = getAuth();

export class TestClock {
  constructor(public ms = Date.now()) {}
  advance(ms: number) { this.ms += ms; }
}

export interface TestDeps extends Deps {
  smsOut: EmulatorSmsProvider;
  emailOut: EmulatorEmailProvider;
  clock: TestClock;
}

export function makeDeps(opts: { maxTransactionWrites?: number } = {}): TestDeps {
  const smsOut = new EmulatorSmsProvider(PROJECT);
  const emailOut = new EmulatorEmailProvider(PROJECT);
  const clock = new TestClock();
  return {
    db, auth, smsOut, emailOut, clock,
    sms: () => smsOut,
    email: () => emailOut,
    now: () => clock.ms,
    appDownloadUrl: () => APP_URL,
    ...(opts.maxTransactionWrites ? { maxTransactionWrites: opts.maxTransactionWrites } : {}),
  };
}

export async function clearEmulators(): Promise<void> {
  const fs = await fetch(`http://${firestoreHost}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
  const au = await fetch(`http://${authHost}/emulator/v1/projects/${PROJECT}/accounts`, { method: 'DELETE' });
  if (!fs.ok || !au.ok) throw new Error(`Could not clear the emulators (${fs.status}, ${au.status})`);
}

interface Seed {
  uid: string;
  role: 'admin' | 'manager' | 'staff';
  deptId: string;
  supervisorId: string | null;
  managerChain: string[];
  active?: boolean;
  phone?: string | null;
  email?: string | null;
  language?: 'en' | 'sw';
  org?: string;
}

/** The organisation from the prototype: Neema at the top, John (Finance) with Asha below him. */
export const seedPeople: Seed[] = [
  { uid: 'neema', role: 'manager', deptId: 'MGT', supervisorId: null, managerChain: [], phone: '+255700000001' },
  { uid: 'idrisa', role: 'admin', deptId: 'ICT', supervisorId: 'neema', managerChain: ['neema'], phone: '+255700000002', email: 'idrisa@example.org' },
  { uid: 'john', role: 'manager', deptId: 'FIN', supervisorId: 'neema', managerChain: ['neema'], phone: '+255700000003' },
  { uid: 'grace', role: 'manager', deptId: 'OPS', supervisorId: 'neema', managerChain: ['neema'], phone: '+255700000004' },
  { uid: 'asha', role: 'staff', deptId: 'FIN', supervisorId: 'john', managerChain: ['john', 'neema'], phone: '+255700000005' },
  { uid: 'baraka', role: 'staff', deptId: 'OPS', supervisorId: 'grace', managerChain: ['grace', 'neema'], phone: '+255700000006' },
  { uid: 'gone', role: 'staff', deptId: 'FIN', supervisorId: 'john', managerChain: ['john', 'neema'], active: false, phone: '+255700000007' },
  { uid: 'outsider', role: 'admin', deptId: 'X', supervisorId: null, managerChain: [], org: OTHER_ORG, phone: '+255700000008', email: 'out@example.org' },
];

export async function seedPerson(p: Seed): Promise<void> {
  const org = p.org ?? ORG;
  await auth.createUser({
    uid: p.uid,
    ...(p.phone ? { phoneNumber: p.phone } : {}),
    ...(p.email ? { email: p.email, password: 'not-used-123' } : {}),
  });
  await auth.setCustomUserClaims(p.uid, { orgId: org });
  await db.doc(`orgs/${org}/users/${p.uid}`).set({
    name: p.uid, role: p.role, deptId: p.deptId, supervisorId: p.supervisorId, managerChain: p.managerChain,
    confidentialDepts: [], jobRole: null, language: p.language ?? 'en', active: p.active ?? true,
  });
  await db.doc(`orgs/${org}/users/${p.uid}/private/contact`).set({ phone: p.phone ?? null, email: p.email ?? null });
}

export async function seed(): Promise<void> {
  await db.doc(`orgs/${ORG}`).set({ name: 'Wizara ya Mfano', timezone: 'Africa/Dar_es_Salaam' });
  await db.doc(`orgs/${OTHER_ORG}`).set({ name: 'Other Org' });
  for (const [id, active] of [['MGT', true], ['ICT', true], ['FIN', true], ['OPS', true], ['HR', true], ['OLD', false]] as const) {
    await db.doc(`orgs/${ORG}/departments/${id}`).set({ name: id, headUserId: null, active });
  }
  await db.doc(`orgs/${OTHER_ORG}/departments/X`).set({ name: 'X', headUserId: null, active: true });
  for (const p of seedPeople) await seedPerson(p);
}

/** request.auth as the callable would see it. Defaults: fresh session, second factor done. */
export function caller(deps: TestDeps, uid: string, opts: { org?: string; signedInDaysAgo?: number; verified?: boolean } = {}): CallerAuth {
  const nowS = Math.floor(deps.clock.ms / 1000);
  const token: Record<string, unknown> = { orgId: opts.org ?? ORG, auth_time: Math.floor(nowS - (opts.signedInDaysAgo ?? 0) * 86_400 - 60) };
  if (opts.verified ?? true) token.adminVerifiedUntil = nowS + 3600;
  return { uid, token };
}

/** Awaits a promise that must fail with an AtmsError carrying `code`. */
export async function expectCode(p: Promise<unknown>, code: string): Promise<AtmsError> {
  try {
    await p;
  } catch (e) {
    if (!(e instanceof AtmsError)) throw e;
    expect(e.code).toBe(code);
    return e;
  }
  throw new Error(`expected failure with ${code}`);
}

export async function userDoc(uid: string, org = ORG): Promise<Record<string, unknown>> {
  const snap = await db.doc(`orgs/${org}/users/${uid}`).get();
  return snap.data() as Record<string, unknown>;
}
