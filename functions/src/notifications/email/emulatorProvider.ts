import type { EmailMessage, EmailProvider, EmailSendResult } from './provider';

/**
 * MOCK/TEMPORARY: records e-mails instead of sending them. Used only in the Firebase Emulator
 * and tests until the real provider is chosen (docs/DECISIONS.md D-08, docs/KNOWN_ISSUES.md).
 * It refuses to run against a real project so it can never silently drop production e-mail.
 *
 * In the emulator an optional `outbox` callback receives each message so a developer can read
 * an admin code in the Emulator UI (the caller writes it to a collection no app can read).
 * Nothing is ever written to the logs.
 */
export class EmulatorEmailProvider implements EmailProvider {
  readonly name = 'emulator';
  readonly sent: EmailMessage[] = [];

  constructor(projectId: string, private readonly outbox?: (message: EmailMessage) => Promise<void>) {
    if (!projectId.startsWith('demo-')) {
      throw new Error('EmulatorEmailProvider may only be used with demo- emulator projects');
    }
  }

  async send(message: EmailMessage): Promise<EmailSendResult> {
    this.sent.push(message);
    if (this.outbox) await this.outbox(message);
    return { ok: true, providerMessageId: `emulator-email-${this.sent.length}` };
  }
}
