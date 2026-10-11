/**
 * Creates the first organisation, one department and the first admin (docs/SPRINT1_CONTRACT.md,
 * "Organisation bootstrap"). Run only through functions/scripts/bootstrap-org.ts; it is not a
 * deployed function. Every later user is added by a verified admin through adminUpsertUser.
 */
import { randomBytes } from 'crypto';
import type { Auth } from 'firebase-admin/auth';
import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { AtmsError, ErrorCode, validationError } from '../shared/errors';
import { log } from '../shared/logger';
import { scrubText } from '../shared/redact';
import type { Department, Language, Org, User, UserContact } from '../shared/model';
import { paths } from './deps';
import { normaliseEmail, normalisePhone } from './validation';

export interface BootstrapArgs {
  orgId: string;
  orgName: string;
  deptName: string;
  adminName: string;
  phone: string | null;
  email: string;
  language: Language;
}

export interface BootstrapResult {
  orgId: string;
  deptId: string;
  adminUid: string;
}

/** Organisation defaults (docs/ARCHITECTURE.md schema; PDD 4.2 and 4.5). Admins change them later. */
export function defaultOrg(name: string): Org {
  return {
    name,
    timezone: 'Africa/Dar_es_Salaam',
    workingHoursEnabled: false, // deadlines count calendar hours until the organisation turns this on
    workingHours: { start: '08:00', end: '17:00', days: [1, 2, 3, 4, 5] },
    reminderHours: [24, 1],
    escalationHours: 24,
    escalationMaxLevel: 2,
    smsEnabled: true,
    smsMonthlyCap: 50_000, // TZS; adjust in Settings
    auditRetentionYears: 3,
  };
}

const ORG_ID = /^[a-z0-9][a-z0-9-]{1,62}$/;

function name(v: string, field: string): string {
  const t = (v ?? '').trim();
  if (t.length === 0 || t.length > 100) throw validationError(field, `${field} must be 1 to 100 characters`);
  return t;
}

export function validateBootstrapArgs(raw: Record<string, string | undefined>): BootstrapArgs {
  const orgId = raw.orgId ?? '';
  if (!ORG_ID.test(orgId)) throw validationError('orgId', 'org id: 2-63 lowercase letters, digits or dashes');
  const email = normaliseEmail(raw.email ?? null);
  // The admin second factor is e-mailed (D-01), so the first admin needs an e-mail address.
  if (!email) throw validationError('email', 'the first admin needs an e-mail address for the admin code');
  const language = (raw.language ?? 'en') as Language;
  if (language !== 'en' && language !== 'sw') throw validationError('language', 'language must be en or sw');
  return {
    orgId,
    orgName: name(raw.orgName ?? '', 'orgName'),
    deptName: name(raw.deptName ?? '', 'deptName'),
    adminName: name(raw.adminName ?? '', 'adminName'),
    phone: raw.phone ? normalisePhone(raw.phone) : null,
    email,
    language,
  };
}

export async function bootstrapOrg(db: Firestore, auth: Auth, args: BootstrapArgs): Promise<BootstrapResult> {
  const orgRef = db.doc(paths.org(args.orgId));
  if ((await orgRef.get()).exists) {
    throw new AtmsError('already-exists', ErrorCode.validation, `Organisation ${args.orgId} already exists`, { field: 'orgId' });
  }

  const record = await auth.createUser({
    ...(args.phone ? { phoneNumber: args.phone } : {}),
    email: args.email,
    password: randomBytes(24).toString('base64url'), // never used: the admin sets one with "forgot password"
  });
  const uid = record.uid;
  const deptRef = db.collection(`${paths.org(args.orgId)}/departments`).doc();
  try {
    await auth.setCustomUserClaims(uid, { orgId: args.orgId });
    await db.runTransaction(async (tx) => {
      if ((await tx.get(orgRef)).exists) {
        throw new AtmsError('already-exists', ErrorCode.validation, `Organisation ${args.orgId} already exists`, { field: 'orgId' });
      }
      const now = FieldValue.serverTimestamp();
      tx.create(orgRef, { ...defaultOrg(args.orgName), createdAt: now, updatedAt: now });
      tx.create(deptRef, { name: args.deptName, headUserId: null, active: true, createdAt: now, updatedAt: now } satisfies Department & Record<string, unknown>);
      tx.create(db.doc(paths.user(args.orgId, uid)), {
        name: args.adminName, role: 'admin', deptId: deptRef.id, supervisorId: null, managerChain: [],
        confidentialDepts: [], jobRole: null, language: args.language, active: true,
      } satisfies User);
      tx.create(db.doc(paths.contact(args.orgId, uid)), { phone: args.phone, email: args.email } satisfies UserContact);
    });
  } catch (err) {
    // Undo the Auth account so the run can be repeated; the original error is rethrown.
    await auth.deleteUser(uid).catch((deleteErr: unknown) => {
      log.error('bootstrap_rollback_failed', { uid, error: scrubText(String((deleteErr as Error)?.message ?? deleteErr)) });
    });
    throw err;
  }
  return { orgId: args.orgId, deptId: deptRef.id, adminUid: uid };
}

/** Entry point for scripts/bootstrap-org.ts: initialises the Admin SDK for `projectId` and runs. */
export async function runBootstrap(projectId: string, args: BootstrapArgs): Promise<BootstrapResult> {
  const { initializeApp } = await import('firebase-admin/app');
  const { getAuth } = await import('firebase-admin/auth');
  const { getFirestore } = await import('firebase-admin/firestore');
  const app = initializeApp({ projectId }, 'bootstrap');
  return bootstrapOrg(getFirestore(app), getAuth(app), args);
}
