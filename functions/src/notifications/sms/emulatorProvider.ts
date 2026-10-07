import type { SmsProvider, SmsSendResult } from './provider';

/**
 * MOCK/TEMPORARY: records messages in memory instead of sending them. Used only in the
 * Firebase Emulator and tests until the real provider is chosen (docs/KNOWN_ISSUES.md).
 * It refuses to run against a real project so it can never silently drop production SMS.
 */
export class EmulatorSmsProvider implements SmsProvider {
  readonly name = 'emulator';
  readonly sent: { to: string; text: string }[] = [];

  constructor(projectId: string) {
    if (!projectId.startsWith('demo-')) {
      throw new Error('EmulatorSmsProvider may only be used with demo- emulator projects');
    }
  }

  async send(toE164: string, text: string): Promise<SmsSendResult> {
    this.sent.push({ to: toE164, text });
    return { ok: true, providerMessageId: `emulator-${this.sent.length}`, costTzs: 0 };
  }
}
