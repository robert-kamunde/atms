import { EmulatorSmsProvider } from '../../src/notifications/sms/emulatorProvider';

describe('emulator SMS provider (MOCK/TEMPORARY)', () => {
  test('records messages in the emulator', async () => {
    const sms = new EmulatorSmsProvider('demo-atms');
    const r = await sms.send('+255700000001', 'ATMS: A task needs your action. Open the app.');
    expect(r.ok).toBe(true);
    expect(sms.sent).toHaveLength(1);
  });
  test('refuses to run against a real project', () => {
    expect(() => new EmulatorSmsProvider('atms-prod')).toThrow();
  });
});
