import {
  canSendCode, checkCode, CODE_TTL_MS, codeMatches, generateCode, hashCode, HOUR_MS, MAX_ATTEMPTS, newSalt,
  recentSends, verifiedUntilSeconds, type StoredAdminCode,
} from '../../src/auth/adminCode';

const NOW = 1_800_000_000_000;

function stored(code: string, extra: Partial<StoredAdminCode> = {}): StoredAdminCode {
  const salt = newSalt();
  return { hash: hashCode(code, salt), salt, expiresAtMs: NOW + CODE_TTL_MS, attempts: 0, sentAtMs: [NOW], ...extra };
}

describe('admin second-factor code (D-01)', () => {
  test('codes are 6 digits, including leading zeros', () => {
    for (let i = 0; i < 200; i++) expect(generateCode()).toMatch(/^\d{6}$/);
  });

  test('only a salted hash is stored; the same code with another salt hashes differently', () => {
    const a = hashCode('123456', 'salt-a');
    expect(a).toMatch(/^[0-9a-f]{64}$/);
    expect(a).not.toContain('123456');
    expect(hashCode('123456', 'salt-b')).not.toBe(a);
    expect(codeMatches('123456', 'salt-a', a)).toBe(true);
    expect(codeMatches('123457', 'salt-a', a)).toBe(false);
    expect(codeMatches('123456', 'salt-a', 'abcd')).toBe(false); // wrong length never throws
  });

  test('right code inside 10 minutes is accepted', () => {
    expect(checkCode(stored('111111'), '111111', NOW + CODE_TTL_MS - 1)).toBe('ok');
  });

  test('a wrong code, an expired code and a used code are refused', () => {
    expect(checkCode(stored('111111'), '222222', NOW)).toBe('wrong');
    expect(checkCode(stored('111111'), '111111', NOW + CODE_TTL_MS)).toBe('expired');
    expect(checkCode(stored('111111', { hash: null }), '111111', NOW)).toBe('no-code');
    expect(checkCode(undefined, '111111', NOW)).toBe('no-code');
  });

  test('after 5 attempts even the right code is refused', () => {
    expect(checkCode(stored('111111', { attempts: MAX_ATTEMPTS - 1 }), '111111', NOW)).toBe('ok');
    expect(checkCode(stored('111111', { attempts: MAX_ATTEMPTS }), '111111', NOW)).toBe('attempts-exceeded');
  });

  test('at most 5 codes per hour', () => {
    const four = [NOW - 50 * 60_000, NOW - 40 * 60_000, NOW - 30 * 60_000, NOW - 1];
    expect(canSendCode(four, NOW)).toBe(true);
    expect(canSendCode([...four, NOW], NOW)).toBe(false);
    // Sends older than an hour no longer count.
    expect(recentSends([NOW - HOUR_MS, NOW - HOUR_MS + 1], NOW)).toEqual([NOW - HOUR_MS + 1]);
    expect(canSendCode([NOW - HOUR_MS - 5, ...four], NOW)).toBe(true);
  });

  test('verification lasts 12 hours, never past the 7-day admin session', () => {
    const nowS = NOW / 1000;
    expect(verifiedUntilSeconds(NOW, nowS - 3600)).toBe(nowS + 12 * 3600);
    const signedIn = nowS - 7 * 86_400 + 2 * 3600; // session ends in 2 hours
    expect(verifiedUntilSeconds(NOW, signedIn)).toBe(nowS + 2 * 3600);
  });
});
