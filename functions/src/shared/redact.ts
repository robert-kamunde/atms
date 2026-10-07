/** Removes titles, text and contact details from anything written to logs. */
const REDACTED_KEYS = new Set(['title', 'description', 'text', 'comment', 'phone', 'email', 'body', 'fileName']);

export function redact(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(redact);
  if (value && typeof value === 'object' && !(value instanceof Date)) {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
      out[k] = REDACTED_KEYS.has(k) ? '[redacted]' : redact(v);
    }
    return out;
  }
  return value;
}
