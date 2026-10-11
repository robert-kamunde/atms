/**
 * Admin second factor (D-01) against the Auth and Firestore emulators: sendAdminCode and
 * verifyAdminCode, plus the blocking sign-up and sign-in decisions (D-02).
 */
import { sendAdminCode, verifyAdminCode } from '../../src/auth/adminCodeHandlers';
import { beforeCreateDecision, beforeSignInDecision } from '../../src/auth/blocking';
import { ErrorCode } from '../../src/shared/errors';
import { auth, caller, clearEmulators, db, expectCode, makeDeps, ORG, seed, type TestDeps } from './helpers';

jest.setTimeout(60_000);

let deps: TestDeps;
beforeEach(async () => {
  await clearEmulators();
  await seed();
  deps = makeDeps();
});

const admin = (opts: { signedInDaysAgo?: number } = {}) => caller(deps, 'idrisa', { verified: false, ...opts });
const lastCode = () => /(\d{6})/.exec(deps.emailOut.sent[deps.emailOut.sent.length - 1].text)?.[1] as string;
const wrong = (code: string) => (code === '000000' ? '111111' : '000000');
const codeDoc = () => db.doc(`orgs/${ORG}/secure/adminCodes/codes/idrisa`);

describe('sendAdminCode and verifyAdminCode', () => {
  test('happy path: e-mails a code, stores only its hash, and sets adminVerifiedUntil', async () => {
    const sent = await sendAdminCode(deps, admin(), {});
    expect(sent.maskedEmail).toBe('i*****@example.org');
    expect(sent.expiresAt).toBe(deps.clock.ms + 10 * 60_000);
    expect(deps.emailOut.sent).toHaveLength(1);
    expect(deps.emailOut.sent[0].to).toBe('idrisa@example.org');
    const code = lastCode();

    const stored = (await codeDoc().get()).data() as Record<string, unknown>;
    expect(JSON.stringify(stored)).not.toContain(code);
    expect(stored.hash).toMatch(/^[0-9a-f]{64}$/);

    const res = await verifyAdminCode(deps, admin(), { code });
    const nowS = Math.floor(deps.clock.ms / 1000);
    expect(res.verifiedUntil).toBe((nowS + 12 * 3600) * 1000);
    expect((await auth.getUser('idrisa')).customClaims).toEqual({ orgId: ORG, adminVerifiedUntil: nowS + 12 * 3600 });

    // Single use.
    await expectCode(verifyAdminCode(deps, admin(), { code }), ErrorCode.codeInvalid);
  });

  test('verification never outlasts the 7-day admin session', async () => {
    await sendAdminCode(deps, admin({ signedInDaysAgo: 6.9 }), {});
    const c = admin({ signedInDaysAgo: 6.9 });
    const res = await verifyAdminCode(deps, c, { code: lastCode() });
    expect(res.verifiedUntil).toBe(((c.token.auth_time as number) + 7 * 86_400) * 1000);
  });

  test('a wrong code is refused and counted; after 5 wrong attempts even the right code is refused', async () => {
    await sendAdminCode(deps, admin(), {});
    const code = lastCode();
    const first = await expectCode(verifyAdminCode(deps, admin(), { code: wrong(code) }), ErrorCode.codeInvalid);
    expect(first.details.attemptsLeft).toBe(4);
    for (let i = 0; i < 4; i++) await expectCode(verifyAdminCode(deps, admin(), { code: wrong(code) }), ErrorCode.codeInvalid);
    await expectCode(verifyAdminCode(deps, admin(), { code }), ErrorCode.codeAttemptsExceeded);
    expect((await auth.getUser('idrisa')).customClaims).toEqual({ orgId: ORG });
  });

  test('a code expires after 10 minutes', async () => {
    await sendAdminCode(deps, admin(), {});
    deps.clock.advance(10 * 60_000);
    await expectCode(verifyAdminCode(deps, admin(), { code: lastCode() }), ErrorCode.codeExpired);
  });

  test('at most 5 codes per hour; a new code replaces the old one', async () => {
    for (let i = 0; i < 5; i++) {
      await sendAdminCode(deps, admin(), {});
      deps.clock.advance(60_000);
    }
    await expectCode(sendAdminCode(deps, admin(), {}), ErrorCode.codeRateLimited);
    expect(deps.emailOut.sent).toHaveLength(5);
    deps.clock.advance(56 * 60_000); // the first send is now more than an hour old
    await sendAdminCode(deps, admin(), {});
    const older = /(\d{6})/.exec(deps.emailOut.sent[4].text)?.[1] as string;
    const newest = lastCode();
    if (older !== newest) await expectCode(verifyAdminCode(deps, admin(), { code: older }), ErrorCode.codeInvalid);
    await verifyAdminCode(deps, admin(), { code: newest });
  });

  test('only admins with a fresh session and an e-mail address can ask for a code', async () => {
    await expectCode(sendAdminCode(deps, caller(deps, 'john'), {}), ErrorCode.permissionDenied);
    await expectCode(verifyAdminCode(deps, caller(deps, 'john'), { code: '123456' }), ErrorCode.permissionDenied);
    await expectCode(sendAdminCode(deps, admin({ signedInDaysAgo: 8 }), {}), ErrorCode.sessionExpired);
    await expectCode(sendAdminCode(deps, undefined, {}), ErrorCode.unauthenticated);
    await db.doc(`orgs/${ORG}/users/idrisa/private/contact`).update({ email: null });
    await expectCode(sendAdminCode(deps, admin(), {}), ErrorCode.adminEmailMissing);
    expect(deps.emailOut.sent).toHaveLength(0);
  });

  test('without an e-mail provider no code is stored', async () => {
    const noEmail: TestDeps = { ...deps, email: () => { throw new Error('no provider'); } };
    await expect(sendAdminCode(noEmail, admin(), {})).rejects.toThrow('no provider');
    expect((await codeDoc().get()).exists).toBe(false);
  });
});

describe('blocking functions (D-02)', () => {
  test('every account creation from the app is refused as not invited', () => {
    expect(beforeCreateDecision()).toBe('not-invited');
  });

  test('sign-in needs an org claim and an active user document', async () => {
    expect(await beforeSignInDecision(db, { uid: 'asha', customClaims: { orgId: ORG } })).toBe('allow');
    expect(await beforeSignInDecision(db, { uid: 'asha' })).toBe('not-invited');
    expect(await beforeSignInDecision(db, { uid: 'stranger', customClaims: { orgId: ORG } })).toBe('not-invited');
    expect(await beforeSignInDecision(db, { uid: 'gone', customClaims: { orgId: ORG } })).toBe('account-deactivated');
  });
});
