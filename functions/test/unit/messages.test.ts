import { adminCodeEmail, invitationSms, maskEmail } from '../../src/auth/messages';
import { EmulatorEmailProvider } from '../../src/notifications/email/emulatorProvider';
import { SMS_MAX_LENGTH } from '../../src/notifications/sms/provider';
import { redact, scrubText } from '../../src/shared/redact';

const URL = 'https://example.invalid/atms';

describe('invitation SMS (PDD 4.1 step 2)', () => {
  test('English and Kiswahili texts name the organisation and the link, nothing else', () => {
    expect(invitationSms('en', 'Wizara ya Fedha', URL)).toBe(`You have been added to Wizara ya Fedha on ATMS. Download the app: ${URL}`);
    expect(invitationSms('sw', 'Wizara ya Fedha', URL)).toBe(`Umeongezwa kwenye Wizara ya Fedha katika ATMS. Pakua programu: ${URL}`);
  });

  test('a long organisation name is shortened to fit one SMS; the link stays whole', () => {
    const text = invitationSms('sw', 'A'.repeat(200), URL);
    expect(text.length).toBeLessThanOrEqual(SMS_MAX_LENGTH);
    expect(text.endsWith(URL)).toBe(true);
  });

  test('refuses to send without a download link', () => {
    expect(() => invitationSms('en', 'Org', '')).toThrow(/APP_DOWNLOAD_URL/);
  });
});

describe('admin code e-mail', () => {
  test('contains the code and the expiry in the user language', () => {
    const en = adminCodeEmail('en', 'a@b.co', '012345', 10);
    expect(en.text).toContain('012345');
    expect(en.text).toContain('10 minutes');
    const sw = adminCodeEmail('sw', 'a@b.co', '012345', 10);
    expect(sw.text).toContain('dakika 10');
  });

  test('masked address hides the local part', () => {
    expect(maskEmail('robert@example.com')).toBe('r*****@example.com');
    expect(maskEmail('ab@x.co')).toBe('a***@x.co');
  });
});

describe('emulator e-mail provider (MOCK/TEMPORARY)', () => {
  test('records messages and passes them to the outbox in the emulator', async () => {
    const box: string[] = [];
    const p = new EmulatorEmailProvider('demo-atms', async (m) => { box.push(m.to); });
    expect((await p.send({ to: 'a@b.co', subject: 's', text: 't' })).ok).toBe(true);
    expect(p.sent).toHaveLength(1);
    expect(box).toEqual(['a@b.co']);
  });
  test('refuses to run against a real project', () => {
    expect(() => new EmulatorEmailProvider('atms-d7f64')).toThrow();
  });
});

describe('log scrubbing', () => {
  test('e-mail addresses, phone numbers and codes are removed from free text', () => {
    const out = scrubText('user robert@example.com with +255712345678 entered 123456');
    expect(out).not.toMatch(/robert|255712345678|123456/);
  });
  test('e-mail subjects are redacted from structured logs', () => {
    expect(redact({ subject: 'x', uid: 'u' })).toEqual({ subject: '[redacted]', uid: 'u' });
  });
});
