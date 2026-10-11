import { EmulatorEmailProvider } from '../../src/notifications/email/emulatorProvider';
import { SmtpEmailProvider, smtpConfigProblems, type MailTransport } from '../../src/notifications/email/smtpProvider';

const message = { to: 'admin@example.org', subject: 'Your ATMS admin code', text: 'Your code is 123456.' };

describe('SMTP e-mail provider', () => {
  test('sends from the configured sender and returns the message id', async () => {
    const sent: unknown[] = [];
    const transport: MailTransport = { sendMail: async (m) => { sent.push(m); return { messageId: '<id@example.org>' }; } };
    const r = await new SmtpEmailProvider('ATMS <atms@example.org>', transport).send(message);
    expect(r).toEqual({ ok: true, providerMessageId: '<id@example.org>' });
    expect(sent).toEqual([{ from: 'ATMS <atms@example.org>', ...message }]);
  });

  test('returns only a short error code when the server refuses', async () => {
    const transport: MailTransport = {
      sendMail: async () => { throw Object.assign(new Error('535 bad password for admin@example.org'), { code: 'EAUTH' }); },
    };
    const r = await new SmtpEmailProvider('atms@example.org', transport).send(message);
    expect(r).toEqual({ ok: false, errorCode: 'EAUTH' });
  });

  test('never passes free text from an error through as the code', async () => {
    const transport: MailTransport = { sendMail: async () => { throw Object.assign(new Error('x'), { code: 'admin@example.org' }); } };
    expect(await new SmtpEmailProvider('atms@example.org', transport).send(message)).toEqual({ ok: false, errorCode: 'SMTP_ERROR' });
  });

  test('reports every missing setting', () => {
    expect(smtpConfigProblems({ host: '', port: 0, user: ' ', password: '', from: 'ATMS' })).toEqual([
      'EMAIL_SMTP_HOST', 'EMAIL_SMTP_PORT', 'EMAIL_SMTP_USER', 'EMAIL_SMTP_PASSWORD', 'EMAIL_FROM',
    ]);
    expect(smtpConfigProblems({ host: 'smtp.example.org', port: 587, user: 'atms', password: 'p', from: 'atms@example.org' })).toEqual([]);
  });
});

describe('emulator e-mail provider (MOCK/TEMPORARY)', () => {
  test('refuses to run against a real project', () => {
    expect(() => new EmulatorEmailProvider('atms-d7f64')).toThrow();
  });
});
