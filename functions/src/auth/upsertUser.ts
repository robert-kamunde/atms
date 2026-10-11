/**
 * adminUpsertUser (docs/SPRINT1_CONTRACT.md, PDD 4.1 and 4.2): a verified admin creates or
 * changes a user. Creates or updates the Firebase Auth account, writes the user and contact
 * documents, rejects reporting loops and recomputes managerChain for the user and everyone below
 * them, all checked again inside a Firestore transaction so concurrent edits cannot create a loop.
 */
import { randomBytes, randomUUID } from 'crypto';
import type { UpdateRequest } from 'firebase-admin/auth';
import { FieldPath, type DocumentReference, type Firestore, type Transaction } from 'firebase-admin/firestore';
import { userAuditDiff } from '../audit/audit';
import { writeUserAudit } from '../audit/writer';
import { MAX_ORG_USERS } from '../shared/config';
import { AtmsError, ErrorCode, validationError } from '../shared/errors';
import { log } from '../shared/logger';
import { scrubText } from '../shared/redact';
import type { Department, Org, User, UserContact } from '../shared/model';
import { requireVerifiedAdmin, type Caller } from '../security/caller';
import { paths, type CallerAuth, type Deps } from './deps';
import { invitationSms } from './messages';
import { chunk, computeChains, ReportingLoopError, sameChain } from './tree';
import { validateUpsertInput, type UpsertUserInput } from './validation';

export const DEFAULT_MAX_TRANSACTION_WRITES = 400;
const CHUNK_SIZE = 400;
const LOCK_MS = 5 * 60_000;

export interface UpsertResult {
  uid: string;
  created: boolean;
}

interface StoredUser extends User {
  id: string;
}

interface TreeLock {
  opId: string;
  lockedUntilMs: number;
  pending: boolean;
}

interface Plan {
  existing: StoredUser | null;
  userDoc: User;
  /** Other users whose supervisorId or managerChain changes (handover of the top and descendants). */
  others: { id: string; supervisorId?: string | null; managerChain: string[] }[];
}

export async function adminUpsertUser(deps: Deps, callerAuth: CallerAuth | undefined, data: unknown): Promise<UpsertResult> {
  const caller = await requireVerifiedAdmin(deps.db, callerAuth, deps.now());
  const input = validateUpsertInput(data);
  await repairIfInterrupted(deps, caller.orgId);
  return input.uid ? updateUser(deps, caller, { ...input, uid: input.uid }) : createUser(deps, caller, input);
}

// ---------- create ----------

async function createUser(deps: Deps, caller: Caller, input: UpsertUserInput): Promise<UpsertResult> {
  const org = caller.orgId;
  // Fail fast (department, supervisor, ...) before an Auth account exists.
  await deps.db.runTransaction((tx) => plan(deps, tx, caller, input, null), { readOnly: true });

  let uid: string;
  try {
    const record = await deps.auth.createUser({
      ...(input.phone ? { phoneNumber: input.phone } : {}),
      ...(input.email ? { email: input.email, password: randomPassword() } : {}),
      disabled: false,
    });
    uid = record.uid;
  } catch (err) {
    throw mapAuthError(err);
  }

  try {
    await deps.auth.setCustomUserClaims(uid, { orgId: org });
    await writeTree(deps, caller, input, uid);
  } catch (err) {
    // Undo the Auth account so the phone number or e-mail is free to try again.
    await deps.auth.deleteUser(uid).catch((deleteErr: unknown) => {
      log.error('upsert_user_rollback_failed', { orgId: org, uid, error: errText(deleteErr) });
    });
    throw err;
  }

  log.info('user_created', { orgId: org, uid, by: caller.uid, role: input.role });
  if (input.phone) await sendInvitation(deps, org, uid, input);
  return { uid, created: true };
}

async function sendInvitation(deps: Deps, org: string, uid: string, input: UpsertUserInput): Promise<void> {
  // The account exists either way; a failed invitation is logged for follow-up, not hidden.
  try {
    const orgSnap = await deps.db.doc(paths.org(org)).get();
    const text = invitationSms(input.language, (orgSnap.data() as Org).name, deps.appDownloadUrl());
    const result = await deps.sms().send(input.phone as string, text);
    if (!result.ok) log.error('invitation_sms_failed', { orgId: org, uid, providerError: result.errorCode });
    else log.info('invitation_sms_sent', { orgId: org, uid, providerMessageId: result.providerMessageId });
  } catch (err) {
    log.error('invitation_sms_failed', { orgId: org, uid, error: errText(err) });
  }
}

// ---------- update ----------

async function updateUser(deps: Deps, caller: Caller, input: UpsertUserInput & { uid: string }): Promise<UpsertResult> {
  const org = caller.orgId;
  const uid = input.uid;
  const checked = await deps.db.runTransaction((tx) => plan(deps, tx, caller, input, uid), { readOnly: true });

  let authUser;
  try {
    authUser = await deps.auth.getUser(uid);
  } catch (err) {
    if (authCode(err) === 'auth/user-not-found') throw new AtmsError('not-found', ErrorCode.notFound, 'User not found.');
    throw err;
  }
  if (authUser.customClaims?.orgId !== org) throw new AtmsError('not-found', ErrorCode.notFound, 'User not found.');

  const change: UpdateRequest = {};
  const oldPhone = authUser.phoneNumber ?? null;
  const oldEmail = authUser.email ?? null;
  if (input.phone !== oldPhone) change.phoneNumber = input.phone;
  if (input.email !== oldEmail) {
    if (input.email === null) {
      throw new AtmsError('failed-precondition', ErrorCode.emailCannotBeRemoved,
        'An e-mail address cannot be removed from an account; change it instead.', { field: 'email' });
    }
    change.email = input.email;
    if (!authUser.providerData.some((p) => p.providerId === 'password')) change.password = randomPassword();
  }
  const authChanged = Object.keys(change).length > 0;
  if (authChanged) {
    try {
      await deps.auth.updateUser(uid, change);
    } catch (err) {
      throw mapAuthError(err);
    }
  }

  try {
    await writeTree(deps, caller, input, uid);
  } catch (err) {
    if (authChanged) {
      const revert: UpdateRequest = { phoneNumber: oldPhone };
      if (oldEmail) revert.email = oldEmail;
      await deps.auth.updateUser(uid, revert).catch((revertErr: unknown) => {
        log.error('upsert_user_auth_revert_failed', { orgId: org, uid, error: errText(revertErr) });
      });
    }
    throw err;
  }

  // A demoted admin loses the second-factor claim at once (rules also check the role).
  if (checked.existing?.role === 'admin' && input.role !== 'admin') {
    await deps.auth.setCustomUserClaims(uid, { orgId: org });
  }
  log.info('user_updated', { orgId: org, uid, by: caller.uid, role: input.role });
  return { uid, created: false };
}

// ---------- reporting tree ----------

/**
 * Re-reads and re-checks everything in a transaction and writes the user, their contact
 * document and every changed managerChain. Large updates (more writes than one commit should
 * carry) hold a lock on the organisation's reporting tree and write the rest in chunks.
 */
async function writeTree(deps: Deps, caller: Caller, input: UpsertUserInput, uid: string): Promise<void> {
  const org = caller.orgId;
  const db = deps.db;
  const maxWrites = deps.maxTransactionWrites ?? DEFAULT_MAX_TRANSACTION_WRITES;
  const opId = randomUUID();

  const deferred = await db.runTransaction(async (tx) => {
    const p = await plan(deps, tx, caller, input, uid);
    const contactRef = db.doc(paths.contact(org, uid));
    const oldContact = p.existing ? ((await tx.get(contactRef)).data() as UserContact | undefined) : undefined;
    const userRef = db.doc(paths.user(org, uid));
    if (p.existing) tx.set(userRef, p.userDoc, { merge: true });
    else tx.create(userRef, p.userDoc);
    tx.set(contactRef, { phone: input.phone, email: input.email } satisfies UserContact);
    const diff = userAuditDiff(
      p.existing ? { ...p.existing, phone: oldContact?.phone ?? null, email: oldContact?.email ?? null } : null,
      { ...p.userDoc, phone: input.phone, email: input.email },
    );
    if (diff) writeUserAudit(tx, db, org, caller.uid, p.existing ? 'user_updated' : 'user_added', uid, { before: diff.before, after: diff.after });

    const changes = p.others;
    const small = changes.length + 2 <= maxWrites;
    const now = changes.filter((c) => small || c.supervisorId !== undefined);
    for (const c of now) tx.update(db.doc(paths.user(org, c.id)), changeFields(c));
    if (small) return [];
    tx.set(db.doc(paths.treeLock(org)), { opId, lockedUntilMs: deps.now() + LOCK_MS, pending: true } satisfies TreeLock);
    return changes.filter((c) => c.supervisorId === undefined);
  });

  if (deferred.length === 0) return;
  log.info('tree_update_chunked', { orgId: org, uid, writes: deferred.length });
  try {
    for (const part of chunk(deferred, CHUNK_SIZE)) {
      const batch = db.batch();
      for (const c of part) batch.update(db.doc(paths.user(org, c.id)), { managerChain: c.managerChain });
      await batch.commit();
    }
    await releaseLock(db, org, opId);
  } catch (err) {
    log.error('tree_update_chunk_failed', { orgId: org, uid, error: errText(err) });
    // Finish the job from the stored supervisors; the user document is already saved.
    await repairChains(deps, org, opId);
  }
}

function changeFields(c: Plan['others'][number]): Record<string, unknown> {
  return c.supervisorId === undefined
    ? { managerChain: c.managerChain }
    : { supervisorId: c.supervisorId, managerChain: c.managerChain };
}

/**
 * Reads and checks everything the change depends on. Used read-only before touching Auth, and
 * again inside the write transaction.
 */
async function plan(deps: Deps, tx: Transaction, caller: Caller, input: UpsertUserInput, uid: string | null): Promise<Plan> {
  const db = deps.db;
  const org = caller.orgId;
  const users = db.collection(paths.users(org));

  const lockSnap = await tx.get(db.doc(paths.treeLock(org)));
  const lock = lockSnap.data() as TreeLock | undefined;
  if (lock && lock.lockedUntilMs > deps.now()) {
    throw new AtmsError('unavailable', ErrorCode.treeBusy, 'The reporting tree is being updated. Try again in a minute.');
  }

  const [orgSnap, deptSnap] = await tx.getAll(db.doc(paths.org(org)), db.doc(paths.dept(org, input.deptId)));
  if (!orgSnap.exists) throw new AtmsError('not-found', ErrorCode.notFound, 'Organisation not found.');
  if (!deptSnap.exists || (deptSnap.data() as Department).active !== true) {
    throw new AtmsError('failed-precondition', ErrorCode.departmentInvalid, 'Choose an active department.', { field: 'deptId' });
  }
  if (input.confidentialDepts.length > 0) {
    const snaps = await tx.getAll(...input.confidentialDepts.map((d) => db.doc(paths.dept(org, d))));
    if (snaps.some((s) => !s.exists)) {
      throw new AtmsError('failed-precondition', ErrorCode.departmentInvalid, 'Unknown department in confidential access.', { field: 'confidentialDepts' });
    }
  }

  let existing: StoredUser | null = null;
  if (uid !== null) {
    const userSnap = await tx.get(db.doc(paths.user(org, uid)));
    if (userSnap.exists) {
      existing = { id: uid, ...(userSnap.data() as User) };
    } else if (input.uid) {
      throw new AtmsError('not-found', ErrorCode.notFound, 'User not found.');
    }
  }
  const active = existing ? existing.active : true;

  // Admin role rules.
  if (existing && existing.role === 'admin' && input.role !== 'admin') {
    if (existing.id === caller.uid) {
      throw new AtmsError('failed-precondition', ErrorCode.selfDemotion, 'You cannot remove your own admin role.', { field: 'role' });
    }
    if (existing.active) {
      const admins = await tx.get(users.where('role', '==', 'admin').where('active', '==', true).limit(2));
      if (admins.size <= 1) {
        throw new AtmsError('failed-precondition', ErrorCode.lastAdmin, 'The last administrator cannot be demoted.', { field: 'role' });
      }
    }
  }

  // Supervisor and top person.
  const outside = new Map<string, string[]>();
  let previousTop: StoredUser | null = null;
  if (input.supervisorId !== null) {
    const supSnap = await tx.get(db.doc(paths.user(org, input.supervisorId)));
    const sup = supSnap.data() as User | undefined;
    if (!sup || sup.active !== true) {
      throw new AtmsError('failed-precondition', ErrorCode.supervisorInvalid, 'Choose an active supervisor.', { field: 'supervisorId' });
    }
    if (uid !== null && (input.supervisorId === uid || sup.managerChain.includes(uid))) throw new ReportingLoopError();
    outside.set(input.supervisorId, sup.managerChain);
  } else if (active) {
    // Exactly one active top person. Making someone else the top hands over: the previous
    // top person now reports to them (otherwise the top could never change without a loop).
    const tops = await tx.get(users.where('supervisorId', '==', null).where('active', '==', true).limit(3));
    const others = tops.docs.filter((d) => d.id !== uid);
    if (others.length > 1) {
      throw new AtmsError('internal', ErrorCode.internal, 'More than one top person found; ask support to repair the reporting tree.');
    }
    if (others.length === 1) previousTop = { id: others[0].id, ...(others[0].data() as User) };
  }

  // Everyone whose chain may change: the user's descendants and, on a handover, everyone
  // below the previous top.
  const affected = new Map<string, StoredUser>();
  const roots = [uid, previousTop?.id].filter((x): x is string => !!x);
  for (const root of roots) {
    const snap = await tx.get(users.where('managerChain', 'array-contains', root).orderBy(FieldPath.documentId()).limit(MAX_ORG_USERS + 1));
    if (snap.size > MAX_ORG_USERS) throw new AtmsError('internal', ErrorCode.internal, 'Organisation too large for one update.');
    for (const d of snap.docs) affected.set(d.id, { id: d.id, ...(d.data() as User) });
  }
  if (previousTop) affected.set(previousTop.id, previousTop);
  if (uid !== null) affected.delete(uid);

  const key = uid ?? '__new__';
  const nodes = new Map<string, string | null>([[key, input.supervisorId]]);
  for (const a of affected.values()) nodes.set(a.id, a.supervisorId);
  if (previousTop) nodes.set(previousTop.id, key);
  const chains = computeChains(nodes, outside);

  const userDoc: User = {
    name: input.name,
    role: input.role,
    deptId: input.deptId,
    supervisorId: input.supervisorId,
    managerChain: chains.get(key) as string[],
    confidentialDepts: input.confidentialDepts,
    jobRole: input.jobRole,
    language: input.language,
    active,
  };
  const others: Plan['others'] = [];
  for (const a of affected.values()) {
    const chain = chains.get(a.id) as string[];
    if (previousTop && a.id === previousTop.id) others.push({ id: a.id, supervisorId: uid, managerChain: chain });
    else if (!sameChain(a.managerChain, chain)) others.push({ id: a.id, managerChain: chain });
  }
  return { existing, userDoc, others };
}

// ---------- lock and repair ----------

async function releaseLock(db: Firestore, org: string, opId: string): Promise<void> {
  await db.runTransaction(async (tx) => {
    const ref = db.doc(paths.treeLock(org));
    const lock = (await tx.get(ref)).data() as TreeLock | undefined;
    if (lock?.opId === opId) tx.delete(ref);
  });
}

/** Repairs chains left half-written by an update that stopped (its lock expired while pending). */
async function repairIfInterrupted(deps: Deps, org: string): Promise<void> {
  const lock = (await deps.db.doc(paths.treeLock(org)).get()).data() as TreeLock | undefined;
  if (lock?.pending && lock.lockedUntilMs <= deps.now()) {
    log.warn('tree_repair_started', { orgId: org });
    await repairChains(deps, org);
  }
}

/**
 * Recomputes every managerChain in the organisation from the stored supervisorIds, under the
 * tree lock. `ownedOpId` lets an interrupted chunked update take over its own lock.
 */
export async function repairChains(deps: Deps, org: string, ownedOpId?: string): Promise<number> {
  const db = deps.db;
  const opId = ownedOpId ?? randomUUID();
  const lockRef = db.doc(paths.treeLock(org));
  await db.runTransaction(async (tx) => {
    const lock = (await tx.get(lockRef)).data() as TreeLock | undefined;
    if (lock && lock.opId !== opId && lock.lockedUntilMs > deps.now()) {
      throw new AtmsError('unavailable', ErrorCode.treeBusy, 'The reporting tree is being updated. Try again in a minute.');
    }
    tx.set(lockRef, { opId, lockedUntilMs: deps.now() + LOCK_MS, pending: true } satisfies TreeLock);
  });

  const all = new Map<string, StoredUser>();
  let last: string | null = null;
  for (;;) {
    let q = db.collection(paths.users(org)).orderBy(FieldPath.documentId()).limit(500);
    if (last) q = q.startAfter(last);
    const page = await q.get();
    for (const d of page.docs) all.set(d.id, { id: d.id, ...(d.data() as User) });
    if (page.size < 500) break;
    last = page.docs[page.size - 1].id;
    if (all.size > MAX_ORG_USERS) throw new AtmsError('internal', ErrorCode.internal, 'Organisation too large to repair.');
  }
  const nodes = new Map<string, string | null>();
  const outside = new Map<string, string[]>();
  for (const u of all.values()) {
    nodes.set(u.id, u.supervisorId);
    if (u.supervisorId && !all.has(u.supervisorId)) outside.set(u.supervisorId, []);
  }
  const chains = computeChains(nodes, outside);
  const changed = [...all.values()].filter((u) => !sameChain(u.managerChain, chains.get(u.id) as string[]));
  for (const part of chunk(changed, CHUNK_SIZE)) {
    const batch = db.batch();
    for (const u of part) batch.update(db.doc(paths.user(org, u.id)) as DocumentReference, { managerChain: chains.get(u.id) });
    await batch.commit();
  }
  await releaseLock(db, org, opId);
  log.info('tree_repaired', { orgId: org, changed: changed.length });
  return changed.length;
}

// ---------- helpers ----------

function randomPassword(): string {
  // Never shown to anyone: e-mail users set their own through "forgot password".
  return randomBytes(24).toString('base64url');
}

function authCode(err: unknown): string | undefined {
  const code = (err as { code?: unknown })?.code;
  return typeof code === 'string' ? code : undefined;
}

function errText(err: unknown): string {
  return scrubText(err instanceof Error ? `${err.name}: ${err.message}` : String(err));
}

function mapAuthError(err: unknown): unknown {
  switch (authCode(err)) {
    case 'auth/phone-number-already-exists':
      return new AtmsError('already-exists', ErrorCode.phoneInUse, 'This phone number is already used by another account.', { field: 'phone' });
    case 'auth/email-already-exists':
      return new AtmsError('already-exists', ErrorCode.emailInUse, 'This e-mail is already used by another account.', { field: 'email' });
    case 'auth/invalid-phone-number':
      return validationError('phone', 'phone is not a valid number');
    case 'auth/invalid-email':
      return validationError('email', 'email is not a valid address');
    default:
      return err;
  }
}
