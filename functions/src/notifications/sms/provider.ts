/**
 * SMS goes through this interface so the provider (Africa's Talking or Beem, decision
 * pending) can be swapped without touching notification logic (PDD 4.6).
 * Callers must pass text that is already safe: never a confidential task title.
 */
export interface SmsSendResult {
  ok: boolean;
  providerMessageId?: string;
  costTzs?: number; // as reported by the provider, used for the monthly cap
  errorCode?: string;
}

export interface SmsProvider {
  readonly name: string;
  send(toE164: string, text: string): Promise<SmsSendResult>;
}

export const SMS_MAX_LENGTH = 160;
