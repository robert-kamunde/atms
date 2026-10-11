/**
 * adminUpsertUser and deactivateUser against the Auth and Firestore emulators
 * (docs/SPRINT1_CONTRACT.md, PDD 4.1 and 4.2).
 */
import { deactivateUser } from '../../src/auth/deactivateUser';
import { adminUpsertUser } from '../../src/auth/upsertUser';
import { beforeSignInDecision } from '../../src/auth/blocking';
import { ErrorCode } from '../../src/shared/errors';
import {
  APP_URL, auth, caller, clearEmulators, db, expectCode, makeDeps, ORG, OTHER_ORG, seed, seedPerson, userDoc, type TestDeps,
} from './helpers';

jest.setTimeout(60_000);

let deps: TestDeps;
beforeEach(async () => {
  await clearEmulators();
  await seed();
  deps = makeDeps();
});

const newStaff = (extra: Record<string, unknown> = {}) => ({
  name: 'Zawadi Said', phone: '+255712000001', email: null, role: 'staff', deptId: 'FIN', supervisorId: 'asha',
  jobRole: 'Clerk', language: 'en', confidentialDepts: [], ...extra,
});

async function existingInput(uid: string, extra: Record<string, unknown> = {}) {
  const u = await userDoc(uid);
  const c = (await db.doc(`orgs/${ORG}/users/${uid}/private/contact`).get()).data() as Record<string, unknown>;
  return {
    uid, name: u.name, phone: c.phone, email: c.email, role: u.role, deptId: u.deptId, supervisorId: u.supervisorId,
    jobRole: u.jobRole, language: u.language, confidentialDepts: u.confidentialDepts, ...extra,
  };
}

describe('adminUpsertUser: create', () => {
  test('creates the Auth account, the user and contact documents, and sends the invitation SMS', async () => {
    const res = await adminUpsertUser(deps, caller(deps, 'idrisa'), newStaff());
    expect(res.created).toBe(true);

    const record = await auth.getUser(res.uid);
    expect(record.phoneNumber).toBe('+255712000001');
    expect(record.customClaims).toEqual({ orgId: ORG });

    expect(await userDoc(res.uid)).toEqual({
      name: 'Zawadi Said', role: 'staff', deptId: 'FIN', supervisorId: 'asha', managerChain: ['asha', 'john', 'neema'],
      confidentialDepts: [], jobRole: 'Clerk', language: 'en', active: true,
    });
    const contact = (await db.doc(`orgs/${ORG}/users/${res.uid}/private/contact`).get()).data();
    expect(contact).toEqual({ phone: '+255712000001', email: null });

    expect(deps.smsOut.sent).toEqual([
      { to: '+255712000001', text: `You have been added to Wizara ya Mfano on ATMS. Download the app: ${APP_URL}` },
    ]);
  });

  test('the invitation is in Kiswahili for Kiswahili users; e-mail-only users get a password account and no SMS', async () => {
    await adminUpsertUser(deps, caller(deps, 'idrisa'), newStaff({ language: 'sw' }));
    expect(deps.smsOut.sent[0].text).toBe(`Umeongezwa kwenye Wizara ya Mfano katika ATMS. Pakua programu: ${APP_URL}`);

    const res = await adminUpsertUser(deps, caller(deps, 'idrisa'), newStaff({ phone: null, email: 'Zawadi@Example.org' }));
    const record = await auth.getUser(res.uid);
    expect(record.email).toBe('zawadi@example.org');
    expect(record.providerData.map((p) => p.providerId)).toContain('password');
    expect(deps.smsOut.sent).toHaveLength(1);
  });

  test('a phone number or e-mail already in use is refused clearly, and nothing is created', async () => {
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa'), newStaff({ phone: '+255700000005' })), ErrorCode.phoneInUse);
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa'), newStaff({ phone: null, email: 'idrisa@example.org' })), ErrorCode.emailInUse);
    const users = await db.collection(`orgs/${ORG}/users`).where('name', '==', 'Zawadi Said').get();
    expect(users.size).toBe(0);
  });

  test('department and supervisor must exist and be active; nothing is created when they are not', async () => {
    const before = (await auth.listUsers()).users.length;
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa'), newStaff({ deptId: 'OLD' })), ErrorCode.departmentInvalid);
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa'), newStaff({ deptId: 'NOPE' })), ErrorCode.departmentInvalid);
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa'), newStaff({ confidentialDepts: ['NOPE'] })), ErrorCode.departmentInvalid);
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa'), newStaff({ supervisorId: 'gone' })), ErrorCode.supervisorInvalid);
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa'), newStaff({ supervisorId: 'outsider' })), ErrorCode.supervisorInvalid);
    expect((await auth.listUsers()).users.length).toBe(before);
    expect(deps.smsOut.sent).toHaveLength(0);
  });

  test('making a new person the top hands over: the previous top now reports to them', async () => {
    const res = await adminUpsertUser(deps, caller(deps, 'idrisa'), newStaff({ role: 'manager', supervisorId: null, phone: '+255712000009', deptId: 'MGT' }));
    const top = res.uid;
    expect((await userDoc(top)).managerChain).toEqual([]);
    expect(await userDoc('neema')).toMatchObject({ supervisorId: top, managerChain: [top] });
    expect((await userDoc('asha')).managerChain).toEqual(['john', 'neema', top]);
    expect((await userDoc('baraka')).managerChain).toEqual(['grace', 'neema', top]);
    const tops = await db.collection(`orgs/${ORG}/users`).where('supervisorId', '==', null).where('active', '==', true).get();
    expect(tops.docs.map((d) => d.id)).toEqual([top]);
  });
});

describe('adminUpsertUser: update', () => {
  test('changes the profile and the Auth phone number', async () => {
    const res = await adminUpsertUser(deps, caller(deps, 'idrisa'), await existingInput('asha', { name: 'Asha M.', phone: '+255712999999', language: 'sw', confidentialDepts: ['HR'] }));
    expect(res).toEqual({ uid: 'asha', created: false });
    expect((await auth.getUser('asha')).phoneNumber).toBe('+255712999999');
    expect(await userDoc('asha')).toMatchObject({ name: 'Asha M.', language: 'sw', confidentialDepts: ['HR'], managerChain: ['john', 'neema'], active: true });
    expect((await db.doc(`orgs/${ORG}/users/asha/private/contact`).get()).data()).toEqual({ phone: '+255712999999', email: null });
    expect(deps.smsOut.sent).toHaveLength(0); // invitations are sent on create only
  });

  test('fields the user owns (consent, mute) survive an admin edit', async () => {
    await db.doc(`orgs/${ORG}/users/asha`).update({ consentVersion: 'v1', muteComments: true });
    await adminUpsertUser(deps, caller(deps, 'idrisa'), await existingInput('asha', { name: 'Asha M.' }));
    expect(await userDoc('asha')).toMatchObject({ consentVersion: 'v1', muteComments: true });
  });

  test('a reporting loop is rejected (John cannot report to Asha, who reports to him)', async () => {
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa'), await existingInput('john', { supervisorId: 'asha' })), ErrorCode.reportingLoop);
    expect(await userDoc('john')).toMatchObject({ supervisorId: 'neema', managerChain: ['neema'] });
  });

  test('managerChain is recomputed for the user and everyone below them', async () => {
    await adminUpsertUser(deps, caller(deps, 'idrisa'), await existingInput('john', { supervisorId: 'grace' }));
    expect((await userDoc('john')).managerChain).toEqual(['grace', 'neema']);
    expect((await userDoc('asha')).managerChain).toEqual(['john', 'grace', 'neema']);
    expect((await userDoc('gone')).managerChain).toEqual(['john', 'grace', 'neema']);
    expect((await userDoc('baraka')).managerChain).toEqual(['grace', 'neema']);
  });

  test('a large subtree is written in chunks under the tree lock, with the same result', async () => {
    const small = makeDeps({ maxTransactionWrites: 3 });
    for (let i = 0; i < 12; i++) {
      await db.doc(`orgs/${ORG}/users/s${i}`).set({
        name: `s${i}`, role: 'staff', deptId: 'FIN', supervisorId: i < 6 ? 'asha' : 's0', managerChain: i < 6 ? ['asha', 'john', 'neema'] : ['s0', 'asha', 'john', 'neema'],
        confidentialDepts: [], jobRole: null, language: 'en', active: true,
      });
    }
    await adminUpsertUser(small, caller(small, 'idrisa'), await existingInput('john', { supervisorId: 'grace' }));
    expect((await userDoc('s3')).managerChain).toEqual(['asha', 'john', 'grace', 'neema']);
    expect((await userDoc('s9')).managerChain).toEqual(['s0', 'asha', 'john', 'grace', 'neema']);
    expect((await db.doc(`orgs/${ORG}/secure/reportingTree`).get()).exists).toBe(false); // lock released
  });

  test('concurrent edits cannot create a loop: of "John under Grace" and "Grace under John" only one wins', async () => {
    const [a, b] = await Promise.allSettled([
      existingInput('john', { supervisorId: 'grace' }).then((i) => adminUpsertUser(deps, caller(deps, 'idrisa'), i)),
      existingInput('grace', { supervisorId: 'john' }).then((i) => adminUpsertUser(deps, caller(deps, 'idrisa'), i)),
    ]);
    const outcomes = [a.status, b.status].sort();
    expect(outcomes).toEqual(['fulfilled', 'rejected']);
    const failed = (a.status === 'rejected' ? a : b) as PromiseRejectedResult;
    expect(failed.reason.code).toBe(ErrorCode.reportingLoop);
    const john = await userDoc('john');
    const grace = await userDoc('grace');
    expect(john.supervisorId === 'grace' && grace.supervisorId === 'john').toBe(false);
  });

  test('an existing e-mail cannot be removed; another org\'s user is not found', async () => {
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa'), await existingInput('idrisa', { email: null })), ErrorCode.emailCannotBeRemoved);
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa'), { ...newStaff(), uid: 'outsider' }), ErrorCode.notFound);
  });

  test('an admin cannot remove their own admin role; demoting another admin clears their second factor', async () => {
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa'), await existingInput('idrisa', { role: 'manager' })), ErrorCode.selfDemotion);
    await seedPerson({ uid: 'admin2', role: 'admin', deptId: 'ICT', supervisorId: 'neema', managerChain: ['neema'], phone: '+255700000010' });
    await auth.setCustomUserClaims('admin2', { orgId: ORG, adminVerifiedUntil: 9_999_999_999 });
    await adminUpsertUser(deps, caller(deps, 'idrisa'), await existingInput('admin2', { role: 'staff' }));
    expect((await userDoc('admin2')).role).toBe('staff');
    expect((await auth.getUser('admin2')).customClaims).toEqual({ orgId: ORG });
  });
});

describe('who may manage users', () => {
  test.each([
    ['signed out', undefined, ErrorCode.unauthenticated],
    ['a manager', 'john', ErrorCode.permissionDenied],
    ['a deactivated user', 'gone', ErrorCode.accountDeactivated],
  ] as const)('%s is refused', async (_l, who, code) => {
    const c = who ? caller(deps, who) : undefined;
    await expectCode(adminUpsertUser(deps, c, newStaff()), code);
    await expectCode(deactivateUser(deps, c, { uid: 'asha' }), code);
  });

  test('an admin without the second factor, or with an old session, or from another org is refused', async () => {
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa', { verified: false }), newStaff()), ErrorCode.adminVerificationRequired);
    await expectCode(deactivateUser(deps, caller(deps, 'idrisa', { verified: false }), { uid: 'asha' }), ErrorCode.adminVerificationRequired);
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa', { signedInDaysAgo: 8 }), newStaff()), ErrorCode.sessionExpired);
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa', { org: OTHER_ORG }), newStaff()), ErrorCode.notInvited);
    await expectCode(adminUpsertUser(deps, { uid: 'idrisa', token: { auth_time: 1 } }, newStaff()), ErrorCode.notInvited);
  });

  test('bad input is refused before anything is read or written', async () => {
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa'), newStaff({ phone: '0712000001' })), ErrorCode.validation);
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa'), newStaff({ managerChain: [] })), ErrorCode.validation);
  });
});

describe('deactivateUser', () => {
  async function task(id: string, data: Record<string, unknown>) {
    await db.doc(`orgs/${ORG}/tasks/${id}`).set({ title: 'secret title', status: 'todo', assigneeIds: ['asha'], deptId: 'FIN', ...data });
  }

  test('deactivates, revokes refresh tokens and flags open tasks (paged), leaving closed and other tasks alone', async () => {
    const batch = db.batch();
    for (let i = 0; i < 205; i++) batch.set(db.doc(`orgs/${ORG}/tasks/open${String(i).padStart(3, '0')}`), { status: i % 3 === 0 ? 'in_progress' : 'todo', assigneeIds: ['asha', 'john'] });
    await batch.commit();
    await task('blocked', { status: 'blocked' });
    await task('awaiting', { status: 'awaiting_check' });
    await task('done', { status: 'done' });
    await task('cancelled', { status: 'cancelled' });
    await task('deleted', { deleted: true });
    await task('johns', { assigneeIds: ['john'] });

    const validAfter = async () => {
      const v = (await auth.getUser('asha')).tokensValidAfterTime;
      return v ? new Date(v).getTime() : 0;
    };
    const before = await validAfter();
    const startedAt = Math.floor(Date.now() / 1000) * 1000; // tokensValidAfterTime has one-second resolution

    const res = await deactivateUser(deps, caller(deps, 'idrisa'), { uid: 'asha' });
    expect(res).toEqual({ flaggedTaskCount: 207 });

    expect((await userDoc('asha')).active).toBe(false);
    const after = await validAfter();
    expect(after).toBeGreaterThan(before);
    expect(after).toBeGreaterThanOrEqual(startedAt);

    const t = async (id: string) => (await db.doc(`orgs/${ORG}/tasks/${id}`).get()).data() as Record<string, unknown>;
    expect(await t('open000')).toMatchObject({ reassignmentNeeded: true, reassignmentReason: 'user_deactivated' });
    expect(await t('open204')).toMatchObject({ reassignmentNeeded: true });
    expect(await t('blocked')).toMatchObject({ reassignmentNeeded: true });
    expect(await t('awaiting')).toMatchObject({ reassignmentNeeded: true }); // awaiting_check is open (D-06)
    for (const id of ['done', 'cancelled', 'deleted', 'johns']) expect((await t(id)).reassignmentNeeded).toBeUndefined();

    // People who reported to her keep that supervisor until an admin changes it.
    expect(await beforeSignInDecision(db, { uid: 'asha', customClaims: { orgId: ORG } })).toBe(ErrorCode.accountDeactivated);
  });

  test('people below a deactivated supervisor keep them until an admin changes it, and must then pick an active one', async () => {
    await deactivateUser(deps, caller(deps, 'idrisa'), { uid: 'john' });
    expect((await userDoc('asha')).supervisorId).toBe('john');
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa'), await existingInput('asha', { name: 'Asha' })), ErrorCode.supervisorInvalid);
    await adminUpsertUser(deps, caller(deps, 'idrisa'), await existingInput('asha', { supervisorId: 'grace' }));
    expect((await userDoc('asha')).managerChain).toEqual(['grace', 'neema']);
  });

  test('an admin cannot deactivate themselves; unknown users are not found', async () => {
    await expectCode(deactivateUser(deps, caller(deps, 'idrisa'), { uid: 'idrisa' }), ErrorCode.selfDeactivation);
    await expectCode(deactivateUser(deps, caller(deps, 'idrisa'), { uid: 'nobody' }), ErrorCode.notFound);
    await expectCode(deactivateUser(deps, caller(deps, 'idrisa'), { uid: 'outsider' }), ErrorCode.notFound);
  });
});

describe('user audit entries (PDD 4.11, KNOWN_ISSUES KI-14)', () => {
  const userEntries = async (uid: string) => {
    const snap = await db.collection(`orgs/${ORG}/audit`).where('subjectUid', '==', uid).get();
    return snap.docs.map((d) => d.data());
  };

  test('adding, changing and deactivating a user each write exactly one entry, readable only by verified admins', async () => {
    const { uid } = await adminUpsertUser(deps, caller(deps, 'idrisa'), newStaff());
    let es = await userEntries(uid);
    expect(es).toHaveLength(1);
    expect(es[0]).toMatchObject({
      action: 'user_added', actorId: 'idrisa', taskId: null, viewerIds: [], confidential: false, madeOffline: false, before: null,
    });
    expect(es[0].after).toMatchObject({ name: 'Zawadi Said', role: 'staff', supervisorId: 'asha', phone: '+255712000001' });

    await adminUpsertUser(deps, caller(deps, 'idrisa'), await existingInput(uid, { role: 'manager', phone: '+255712000002' }));
    es = await userEntries(uid);
    const updated = es.filter((e) => e.action === 'user_updated');
    expect(updated).toHaveLength(1);
    expect(updated[0].before).toEqual({ role: 'staff', phone: '+255712000001' });
    expect(updated[0].after).toEqual({ role: 'manager', phone: '+255712000002' });

    // Saving without a change is not an action.
    await adminUpsertUser(deps, caller(deps, 'idrisa'), await existingInput(uid));
    expect((await userEntries(uid)).filter((e) => e.action === 'user_updated')).toHaveLength(1);

    await deactivateUser(deps, caller(deps, 'idrisa'), { uid });
    await deactivateUser(deps, caller(deps, 'idrisa'), { uid }); // already inactive: no second entry
    const deactivated = (await userEntries(uid)).filter((e) => e.action === 'user_deactivated');
    expect(deactivated).toHaveLength(1);
    expect(deactivated[0]).toMatchObject({ before: { active: true }, after: { active: false }, actorId: 'idrisa' });
  });

  test('a refused change writes no entry', async () => {
    await expectCode(adminUpsertUser(deps, caller(deps, 'idrisa'), newStaff({ deptId: 'OLD' })), ErrorCode.departmentInvalid);
    const snap = await db.collection(`orgs/${ORG}/audit`).get();
    expect(snap.size).toBe(0);
  });
});
