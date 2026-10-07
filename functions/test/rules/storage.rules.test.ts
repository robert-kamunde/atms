/**
 * Cloud Storage rules tests: attachments follow their task's access rule (PDD 4.7, 4.8).
 */
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { ref, uploadBytes, getBytes, deleteObject } from 'firebase/storage';
import { as, makeEnv, ORG, seed } from './fixtures';

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await makeEnv();
});
afterAll(async () => {
  await env.cleanup();
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await seed(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    await uploadBytes(ref(ctx.storage(), `orgs/${ORG}/tasks/conf/att1`), new Uint8Array([1, 2, 3]), { contentType: 'application/pdf' });
    await uploadBytes(ref(ctx.storage(), `orgs/${ORG}/tasks/normal/att2`), new Uint8Array([1, 2, 3]), { contentType: 'image/jpeg' });
  });
});

const jpeg = { contentType: 'image/jpeg' };

describe('attachments in Cloud Storage', () => {
  test('a task viewer uploads a photo up to 10 MB', async () => {
    const storage = as(env, 'asha').storage();
    await assertSucceeds(uploadBytes(ref(storage, `orgs/${ORG}/tasks/normal/new1`), new Uint8Array(300 * 1024), jpeg));
  });

  test('files over 10 MB are refused', async () => {
    const storage = as(env, 'asha').storage();
    await assertFails(uploadBytes(ref(storage, `orgs/${ORG}/tasks/normal/big`), new Uint8Array(10 * 1024 * 1024 + 1), jpeg));
  });

  test('unsupported file types are refused', async () => {
    const storage = as(env, 'asha').storage();
    await assertFails(uploadBytes(ref(storage, `orgs/${ORG}/tasks/normal/x`), new Uint8Array(10), { contentType: 'application/x-msdownload' }));
  });

  test('files cannot be overwritten or deleted from the app', async () => {
    const storage = as(env, 'asha').storage();
    await assertFails(uploadBytes(ref(storage, `orgs/${ORG}/tasks/normal/att2`), new Uint8Array(10), jpeg));
    await assertFails(deleteObject(ref(storage, `orgs/${ORG}/tasks/normal/att2`)));
  });

  test('CRITICAL: confidential attachments are unreadable without access', async () => {
    for (const who of ['asha', 'john', 'grace', 'idrisa'] as const) {
      await assertFails(getBytes(ref(as(env, who).storage(), `orgs/${ORG}/tasks/conf/att1`)));
    }
    await assertSucceeds(getBytes(ref(as(env, 'rehema').storage(), `orgs/${ORG}/tasks/conf/att1`)));
    await assertSucceeds(getBytes(ref(as(env, 'neema').storage(), `orgs/${ORG}/tasks/conf/att1`)));
  });

  test('nobody outside the task can upload to it', async () => {
    await assertFails(uploadBytes(ref(as(env, 'baraka').storage(), `orgs/${ORG}/tasks/normal/n`), new Uint8Array(10), jpeg));
    await assertFails(uploadBytes(ref(as(env, 'asha').storage(), `orgs/${ORG}/tasks/conf/n`), new Uint8Array(10), jpeg));
  });

  test('paths outside task attachments are closed', async () => {
    await assertFails(uploadBytes(ref(as(env, 'idrisa').storage(), `reports/${ORG}/r.pdf`), new Uint8Array(10), { contentType: 'application/pdf' }));
  });
});
