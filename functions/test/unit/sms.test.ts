import { BEEM_SEND_URL, BeemSmsProvider, beemConfigProblems, type HttpPost } from '../../src/notifications/sms/beemProvider';
import { EmulatorSmsProvider } from '../../src/notifications/sms/emulatorProvider';

describe('emulator SMS provider (MOCK/TEMPORARY)', () => {
  test('records messages in the emulator', async () => {
    const sms = new EmulatorSmsProvider('demo-atms');
    const r = await sms.send('+255700000001', 'ATMS: A task needs your action. Open the app.');
    expect(r.ok).toBe(true);
    expect(sms.sent).toHaveLength(1);
  });
  test('refuses to run against a real project', () => {
    expect(() => new EmulatorSmsProvider('atms-prod')).toThrow();
  });
});

describe('Beem SMS provider', () => {
  const config = { apiKey: 'key', secretKey: 'secret', senderId: 'INFO' };
  const reply = (status: number, data: unknown): HttpPost => async () => ({ status, json: async () => data });

  test('posts the Beem request with basic auth and the number without +', async () => {
    const calls: { url: string; init: Parameters<HttpPost>[1] }[] = [];
    const post: HttpPost = async (url, init) => {
      calls.push({ url, init });
      return { status: 200, json: async () => ({ successful: true, request_id: 42, code: 100, valid: 1, invalid: 0 }) };
    };
    const r = await new BeemSmsProvider(config, post).send('+255712818139', 'ATMS: A task needs your action. Open the app.');
    expect(r).toEqual({ ok: true, providerMessageId: '42' });
    expect(calls[0].url).toBe(BEEM_SEND_URL);
    expect(calls[0].init.headers.Authorization).toBe(`Basic ${Buffer.from('key:secret').toString('base64')}`);
    expect(JSON.parse(calls[0].init.body)).toEqual({
      source_addr: 'INFO',
      encoding: 0,
      message: 'ATMS: A task needs your action. Open the app.',
      recipients: [{ recipient_id: 1, dest_addr: '255712818139' }],
    });
  });

  test('reports a refused or invalid send as a short code', async () => {
    expect(await new BeemSmsProvider(config, reply(401, { code: 120, message: 'Invalid api_key' })).send('+255712818139', 'x')).toEqual({ ok: false, errorCode: 'BEEM_120' });
    expect(await new BeemSmsProvider(config, reply(200, { successful: true, code: 100, valid: 0, invalid: 1 })).send('+255712818139', 'x')).toEqual({ ok: false, errorCode: 'BEEM_100' });
    expect(await new BeemSmsProvider(config, reply(502, 'gateway')).send('+255712818139', 'x')).toEqual({ ok: false, errorCode: 'HTTP_502' });
  });

  test('maps timeouts and network errors without detail', async () => {
    const timeout: HttpPost = async () => { throw Object.assign(new Error('t'), { name: 'TimeoutError' }); };
    const down: HttpPost = async () => { throw new Error('ECONNRESET 255712818139'); };
    expect(await new BeemSmsProvider(config, timeout).send('+255712818139', 'x')).toEqual({ ok: false, errorCode: 'TIMEOUT' });
    expect(await new BeemSmsProvider(config, down).send('+255712818139', 'x')).toEqual({ ok: false, errorCode: 'NETWORK' });
  });

  test('refuses bad numbers and over-long text before calling Beem', async () => {
    const post = jest.fn<ReturnType<HttpPost>, Parameters<HttpPost>>();
    const beem = new BeemSmsProvider(config, post);
    expect(await beem.send('0712818139', 'x')).toEqual({ ok: false, errorCode: 'INVALID_NUMBER' });
    expect(await beem.send('+255712818139', 'x'.repeat(161))).toEqual({ ok: false, errorCode: 'INVALID_TEXT' });
    expect(post).not.toHaveBeenCalled();
  });

  test('lists missing settings', () => {
    expect(beemConfigProblems({ apiKey: '', secretKey: '', senderId: '' })).toEqual(['BEEM_API_KEY', 'BEEM_SECRET_KEY', 'SMS_SENDER_ID']);
    expect(beemConfigProblems(config)).toEqual([]);
  });
});
