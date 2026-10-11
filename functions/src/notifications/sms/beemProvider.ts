import { SMS_MAX_LENGTH, type SmsProvider, type SmsSendResult } from './provider';

/**
 * Sends SMS through Beem (docs/DECISIONS.md D-09): POST https://apisms.beem.africa/v1/send with
 * HTTP Basic auth (API key and secret key from Secret Manager). Beem takes the number in
 * international form without the plus sign. The sender name (SMS_SENDER_ID) must be one Beem
 * has approved for the account; until a TCRA-registered name is approved, use Beem's default
 * sender (INFO).
 *
 * Only a short error code is ever returned; the number, the text and Beem's reply are never
 * logged. Beem does not report the price in the send reply, so `costTzs` is left unset.
 */
export const BEEM_SEND_URL = 'https://apisms.beem.africa/v1/send';

export interface BeemConfig {
  apiKey: string;
  secretKey: string;
  /** Approved sender name, for example ATMS. */
  senderId: string;
}

/** The one call the provider needs from fetch (a fake in tests). */
export type HttpPost = (url: string, init: { method: 'POST'; headers: Record<string, string>; body: string; signal: AbortSignal }) => Promise<{
  status: number;
  json(): Promise<unknown>;
}>;

/** Names of the settings that are missing; empty when the config can be used. */
export function beemConfigProblems(config: BeemConfig): string[] {
  const problems: string[] = [];
  if (!config.apiKey) problems.push('BEEM_API_KEY');
  if (!config.secretKey) problems.push('BEEM_SECRET_KEY');
  if (!/^[A-Za-z0-9 ._-]{1,11}$/.test(config.senderId)) problems.push('SMS_SENDER_ID');
  return problems;
}

export class BeemSmsProvider implements SmsProvider {
  readonly name = 'beem';

  constructor(
    private readonly config: BeemConfig,
    private readonly post: HttpPost = fetch as unknown as HttpPost,
    private readonly timeoutMs = 15_000,
  ) {}

  async send(toE164: string, text: string): Promise<SmsSendResult> {
    if (!/^\+[1-9]\d{7,14}$/.test(toE164)) return { ok: false, errorCode: 'INVALID_NUMBER' };
    if (text.length === 0 || text.length > SMS_MAX_LENGTH) return { ok: false, errorCode: 'INVALID_TEXT' };
    const body = {
      source_addr: this.config.senderId,
      encoding: 0,
      message: text,
      recipients: [{ recipient_id: 1, dest_addr: toE164.slice(1) }],
    };
    const auth = Buffer.from(`${this.config.apiKey}:${this.config.secretKey}`).toString('base64');
    try {
      const res = await this.post(BEEM_SEND_URL, {
        method: 'POST',
        headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/json', Accept: 'application/json' },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(this.timeoutMs),
      });
      const data = (await res.json().catch(() => ({}))) as { successful?: unknown; request_id?: unknown; code?: unknown; valid?: unknown };
      if (res.status >= 200 && res.status < 300 && data.successful === true && data.valid !== 0) {
        return { ok: true, providerMessageId: data.request_id != null ? String(data.request_id) : undefined };
      }
      const code = typeof data.code === 'number' ? `BEEM_${data.code}` : `HTTP_${res.status}`;
      return { ok: false, errorCode: code };
    } catch (err) {
      const name = (err as { name?: unknown })?.name;
      return { ok: false, errorCode: name === 'TimeoutError' || name === 'AbortError' ? 'TIMEOUT' : 'NETWORK' };
    }
  }
}
