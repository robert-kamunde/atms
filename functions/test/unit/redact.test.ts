import { redact } from '../../src/shared/redact';

describe('log redaction', () => {
  test('titles, text and phone numbers never reach the logs, at any depth', () => {
    const out = redact({
      taskId: 't1', title: 'Disciplinary case', nested: { comment: 'secret', phone: '+255700000000', status: 'done' },
      list: [{ description: 'x', id: 1 }],
    });
    expect(out).toEqual({
      taskId: 't1', title: '[redacted]', nested: { comment: '[redacted]', phone: '[redacted]', status: 'done' },
      list: [{ description: '[redacted]', id: 1 }],
    });
  });
});
