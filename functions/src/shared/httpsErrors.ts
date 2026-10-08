/** Maps handler failures to HttpsError for callable functions (kept apart so pure modules stay light). */
import { HttpsError } from 'firebase-functions/v2/https';
import { AtmsError, ErrorCode } from './errors';
import { log } from './logger';
import { scrubText } from './redact';

/**
 * Converts anything thrown by a handler into an HttpsError. Expected failures are logged as
 * warnings; anything else is logged as an error (scrubbed of contact details) and returned to
 * the app as `internal`, never with its raw message.
 */
export function toHttpsError(err: unknown, fn: string): HttpsError {
  if (err instanceof AtmsError) {
    log.warn('callable_refused', { fn, code: err.code, ...err.details });
    return new HttpsError(err.httpsCode, err.message, { ...err.details, code: err.code });
  }
  if (err instanceof HttpsError) {
    log.warn('callable_refused', { fn, httpsCode: err.code });
    return err;
  }
  const e = err as { name?: string; code?: unknown; message?: string; stack?: string };
  log.error('callable_failed', {
    fn,
    errorName: e?.name,
    errorCode: typeof e?.code === 'string' ? e.code : undefined,
    errorMessage: scrubText(String(e?.message ?? err)),
  });
  return new HttpsError('internal', 'Something went wrong. Please try again.', { code: ErrorCode.internal });
}
