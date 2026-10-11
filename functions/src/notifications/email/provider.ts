/**
 * E-mail goes through this interface so the provider (one transactional e-mail service shared
 * by admin codes and report e-mails, docs/DECISIONS.md D-08) can be swapped without touching
 * the callers. Callers must pass text that is already safe: never a task title.
 */
export interface EmailMessage {
  to: string;
  subject: string;
  text: string;
}

export interface EmailSendResult {
  ok: boolean;
  providerMessageId?: string;
  errorCode?: string;
}

export interface EmailProvider {
  readonly name: string;
  send(message: EmailMessage): Promise<EmailSendResult>;
}
