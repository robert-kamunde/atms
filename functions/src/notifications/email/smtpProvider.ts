import { createTransport } from 'nodemailer';
import type { EmailMessage, EmailProvider, EmailSendResult } from './provider';

/**
 * Sends e-mail through an SMTP server, such as the organisation's own mailbox (docs/DECISIONS.md
 * D-08). The password comes from Secret Manager; host, port, user and sender address are
 * per-project parameters (functions/.env.<projectId>). TLS is always required: port 465 uses
 * implicit TLS, any other port must upgrade with STARTTLS or the send fails.
 *
 * Errors are returned as a short code (for example EAUTH); the message, recipient and server
 * reply are never logged or returned.
 */
export interface SmtpConfig {
  host: string;
  port: number;
  user: string;
  password: string;
  /** Sender, for example `ATMS <atms@example.org>`. */
  from: string;
}

/** The one call the provider needs from a nodemailer transport (a fake in tests). */
export interface MailTransport {
  sendMail(mail: { from: string; to: string; subject: string; text: string }): Promise<{ messageId?: string }>;
}

/** Names of the settings that are missing or invalid; empty when the config can be used. */
export function smtpConfigProblems(config: SmtpConfig): string[] {
  const problems: string[] = [];
  if (!config.host.trim()) problems.push('EMAIL_SMTP_HOST');
  if (!Number.isInteger(config.port) || config.port < 1 || config.port > 65535) problems.push('EMAIL_SMTP_PORT');
  if (!config.user.trim()) problems.push('EMAIL_SMTP_USER');
  if (!config.password) problems.push('EMAIL_SMTP_PASSWORD');
  if (!config.from.includes('@')) problems.push('EMAIL_FROM');
  return problems;
}

export function smtpTransport(config: SmtpConfig): MailTransport {
  const implicitTls = config.port === 465;
  return createTransport({
    host: config.host,
    port: config.port,
    secure: implicitTls,
    requireTLS: !implicitTls,
    auth: { user: config.user, pass: config.password },
    connectionTimeout: 10_000,
    greetingTimeout: 10_000,
    socketTimeout: 20_000,
  });
}

export class SmtpEmailProvider implements EmailProvider {
  readonly name = 'smtp';

  constructor(
    private readonly from: string,
    private readonly transport: MailTransport,
  ) {}

  async send(message: EmailMessage): Promise<EmailSendResult> {
    try {
      const info = await this.transport.sendMail({ from: this.from, to: message.to, subject: message.subject, text: message.text });
      return { ok: true, providerMessageId: info.messageId };
    } catch (err) {
      const code = (err as { code?: unknown })?.code;
      return { ok: false, errorCode: typeof code === 'string' && /^[A-Z_]{1,32}$/.test(code) ? code : 'SMTP_ERROR' };
    }
  }
}
