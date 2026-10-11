/**
 * Organisation bootstrap (scripts/bootstrap-org.ts) against the emulators, followed by the
 * first admin's second factor and first user, end to end through the handlers.
 */
import { sendAdminCode, verifyAdminCode } from '../../src/auth/adminCodeHandlers';
import { bootstrapOrg, validateBootstrapArgs } from '../../src/auth/bootstrap';
import { adminUpsertUser } from '../../src/auth/upsertUser';
import { ErrorCode } from '../../src/shared/errors';
import { auth, clearEmulators, db, expectCode, makeDeps } from './helpers';

jest.setTimeout(60_000);

beforeEach(clearEmulators);

const raw: Record<string, string | undefined> = {
  orgId: 'pilot', orgName: 'Wizara ya Mfano', deptName: 'ICT', adminName: 'Idrisa',
  phone: '+255712345678', email: 'Idrisa@Example.org',
};
const args = () => validateBootstrapArgs(raw);

test('creates the organisation with defaults, a department and the first admin', async () => {
  const res = await bootstrapOrg(db, auth, args());
  const org = (await db.doc('orgs/pilot').get()).data() as Record<string, unknown>;
  expect(org).toMatchObject({
    name: 'Wizara ya Mfano', timezone: 'Africa/Dar_es_Salaam', workingHoursEnabled: false,
    workingHours: { start: '08:00', end: '17:00', days: [1, 2, 3, 4, 5] }, reminderHours: [24, 1],
    escalationHours: 24, escalationMaxLevel: 2, smsEnabled: true, auditRetentionYears: 3,
  });
  expect(Number.isInteger(org.smsMonthlyCap)).toBe(true);
  expect((await db.doc(`orgs/pilot/departments/${res.deptId}`).get()).data()).toMatchObject({ name: 'ICT', active: true, headUserId: null });
  expect((await db.doc(`orgs/pilot/users/${res.adminUid}`).get()).data()).toEqual({
    name: 'Idrisa', role: 'admin', deptId: res.deptId, supervisorId: null, managerChain: [], confidentialDepts: [],
    jobRole: null, language: 'en', active: true,
  });
  expect((await db.doc(`orgs/pilot/users/${res.adminUid}/private/contact`).get()).data()).toEqual({ phone: '+255712345678', email: 'idrisa@example.org' });
  const record = await auth.getUser(res.adminUid);
  expect(record.customClaims).toEqual({ orgId: 'pilot' });
  expect(record.phoneNumber).toBe('+255712345678');

  // Never twice.
  await expectCode(bootstrapOrg(db, auth, args()), ErrorCode.validation);
  expect((await auth.listUsers()).users).toHaveLength(1);
});

test('the first admin verifies the second factor and adds the first user', async () => {
  const res = await bootstrapOrg(db, auth, args());
  const deps = makeDeps();
  const nowS = Math.floor(deps.clock.ms / 1000);
  const token: Record<string, unknown> = { orgId: 'pilot', auth_time: nowS - 60 };
  await sendAdminCode(deps, { uid: res.adminUid, token }, {});
  const code = /(\d{6})/.exec(deps.emailOut.sent[0].text)?.[1] as string;
  const { verifiedUntil } = await verifyAdminCode(deps, { uid: res.adminUid, token }, { code });
  token.adminVerifiedUntil = verifiedUntil / 1000; // what getIdToken(true) brings back

  const created = await adminUpsertUser(deps, { uid: res.adminUid, token }, {
    name: 'Neema', phone: '+255712000002', email: null, role: 'manager', deptId: res.deptId, supervisorId: res.adminUid,
    jobRole: 'Director', language: 'sw', confidentialDepts: [res.deptId],
  });
  expect((await db.doc(`orgs/pilot/users/${created.uid}`).get()).data()).toMatchObject({ managerChain: [res.adminUid] });
});

test('bootstrap input is validated: org id format and an admin e-mail are required', () => {
  expect(() => validateBootstrapArgs({ ...raw, orgId: 'Bad Id' })).toThrow();
  expect(() => validateBootstrapArgs({ ...raw, email: undefined })).toThrow(/e-mail/);
  expect(() => validateBootstrapArgs({ ...raw, phone: '0712' })).toThrow();
});
