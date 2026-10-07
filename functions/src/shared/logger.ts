/**
 * Structured logging that never writes task titles, descriptions, comment text or phone
 * numbers. Cloud Logging is readable by project staff who may not be allowed to see
 * confidential tasks (master instructions, "Confidentiality").
 */
import { logger as fnLogger } from 'firebase-functions/v2';
import { redact } from './redact';

export const log = {
  info: (msg: string, data?: Record<string, unknown>) => fnLogger.info(msg, redact(data ?? {})),
  warn: (msg: string, data?: Record<string, unknown>) => fnLogger.warn(msg, redact(data ?? {})),
  error: (msg: string, data?: Record<string, unknown>) => fnLogger.error(msg, redact(data ?? {})),
};
