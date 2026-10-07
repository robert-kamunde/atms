import { isAdminVerified, isSessionFresh } from '../../src/security/session';

const NOW = 1_800_000_000;
const DAY = 86_400;

describe('session policy (PDD 4.1)', () => {
  test('staff and managers stay signed in for 30 days', () => {
    expect(isSessionFresh({ auth_time: NOW - 29 * DAY }, 'staff', NOW)).toBe(true);
    expect(isSessionFresh({ auth_time: NOW - 31 * DAY }, 'manager', NOW)).toBe(false);
  });
  test('admins must sign in again every 7 days', () => {
    expect(isSessionFresh({ auth_time: NOW - 6 * DAY }, 'admin', NOW)).toBe(true);
    expect(isSessionFresh({ auth_time: NOW - 8 * DAY }, 'admin', NOW)).toBe(false);
  });
  test('a token without auth_time is never fresh', () => {
    expect(isSessionFresh({}, 'staff', NOW)).toBe(false);
  });
  test('admin powers need a current second-factor claim', () => {
    const fresh = { auth_time: NOW - DAY };
    expect(isAdminVerified(fresh, 'admin', NOW)).toBe(false);
    expect(isAdminVerified({ ...fresh, adminVerifiedUntil: NOW + 60 }, 'admin', NOW)).toBe(true);
    expect(isAdminVerified({ ...fresh, adminVerifiedUntil: NOW - 1 }, 'admin', NOW)).toBe(false);
    expect(isAdminVerified({ ...fresh, adminVerifiedUntil: NOW + 60 }, 'manager', NOW)).toBe(false);
  });
});
