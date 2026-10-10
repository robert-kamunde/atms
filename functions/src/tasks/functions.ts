/**
 * Cloud Functions wrappers for Sprint 2 (tasks, audit, visibility). They only extract the event
 * or caller and map errors; the logic lives in the handler modules. Triggers retry on failure
 * (every handler is idempotent), and failures are logged without task content and rethrown,
 * never swallowed. App Check is in monitor mode (D-04).
 */
import { getFirestore } from 'firebase-admin/firestore';
import { onCall, type CallableRequest } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { REGION } from '../shared/config';
import { toHttpsError } from '../shared/httpsErrors';
import { log } from '../shared/logger';
import { scrubText } from '../shared/redact';
import { handleTaskCreated } from './assignTask';
import type { TaskDeps } from './deps';
import { reassignTask } from './reassignTask';
import { handleTaskUpdated } from './taskUpdated';
import { handleUserUpdated } from './visibility';

function deps(): TaskDeps {
  return { db: getFirestore(), now: () => Date.now() };
}

async function guarded<T>(fn: string, ids: Record<string, unknown>, run: () => Promise<T>): Promise<T> {
  try {
    return await run();
  } catch (err) {
    const e = err as { name?: string; code?: unknown; message?: string };
    log.error('trigger_failed', {
      fn, ...ids, errorName: e?.name, errorCode: typeof e?.code === 'string' ? e.code : undefined,
      errorMessage: scrubText(String(e?.message ?? err)),
    });
    throw err; // retried by the platform (retry: true); the handlers are idempotent
  }
}

const TASK_DOC = 'orgs/{org}/tasks/{taskId}';
const USER_DOC = 'orgs/{org}/users/{uid}';

export const onTaskCreatedFn = onDocumentCreated({ document: TASK_DOC, region: REGION, retry: true }, (event) =>
  guarded('onTaskCreated', { orgId: event.params.org, taskId: event.params.taskId }, () =>
    handleTaskCreated(deps(), { org: event.params.org, taskId: event.params.taskId, eventId: event.id })));

export const onTaskUpdatedFn = onDocumentUpdated({ document: TASK_DOC, region: REGION, retry: true }, (event) =>
  guarded('onTaskUpdated', { orgId: event.params.org, taskId: event.params.taskId }, async () => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return null;
    return handleTaskUpdated(deps(), { org: event.params.org, taskId: event.params.taskId, eventId: event.id, before, after });
  }));

export const onUserUpdatedFn = onDocumentUpdated({ document: USER_DOC, region: REGION, retry: true }, (event) =>
  guarded('onUserUpdated', { orgId: event.params.org, uid: event.params.uid }, () =>
    handleUserUpdated(deps(), { org: event.params.org, uid: event.params.uid, before: event.data?.before.data(), after: event.data?.after.data() })));

export const reassignTaskFn = onCall({ region: REGION, enforceAppCheck: false }, async (req: CallableRequest<unknown>) => {
  if (!req.app) log.warn('app_check_missing', { fn: 'reassignTask' });
  const caller = req.auth ? { uid: req.auth.uid, token: req.auth.token as unknown as Record<string, unknown> } : undefined;
  try {
    return await reassignTask(deps(), caller, req.data);
  } catch (err) {
    throw toHttpsError(err, 'reassignTask');
  }
});
