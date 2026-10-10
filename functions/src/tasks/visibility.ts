/**
 * Visibility upkeep (SPRINT2_CONTRACT "Visibility upkeep"): when a user's managerChain changes,
 * viewerIds is recomputed for every task (open or closed) where they are an assignee, in pages of
 * at most 200, so managers see their new team's history and former managers stop seeing it.
 * Each page is re-read and written in one transaction, so a concurrent reassignment is never
 * overwritten with stale assignees. Recomputing is idempotent, so retries are safe.
 */
import { FieldPath } from 'firebase-admin/firestore';
import { paths } from '../auth/deps';
import { sameValue } from '../audit/audit';
import { log } from '../shared/logger';
import type { Task } from '../shared/model';
import { computeViewerIds } from './assignment';
import { TASK_PAGE, type TaskDeps } from './deps';
import { chainsOf, readPeople } from './people';

export function managerChainChanged(before: Record<string, unknown> | undefined, after: Record<string, unknown> | undefined): boolean {
  return !!before && !!after && !sameValue(before.managerChain ?? [], after.managerChain ?? []);
}

/** Recomputes viewerIds of the user's tasks. Returns the number of tasks whose viewerIds changed. */
export async function recomputeViewerIdsForAssignee(deps: TaskDeps, org: string, uid: string, pageSize = TASK_PAGE): Promise<number> {
  const { db } = deps;
  const size = Math.min(Math.max(1, pageSize), TASK_PAGE);
  let updated = 0;
  let last: string | null = null;
  for (;;) {
    let q = db.collection(paths.tasks(org)).where('assigneeIds', 'array-contains', uid).orderBy(FieldPath.documentId()).limit(size);
    if (last) q = q.startAfter(last);
    const page = await q.get();
    if (page.empty) break;
    const refs = page.docs.map((d) => d.ref);
    updated += await db.runTransaction(async (tx) => {
      const snaps = await tx.getAll(...refs);
      const tasks = snaps
        .filter((s) => s.exists)
        .map((s) => ({ ref: s.ref, task: s.data() as Task }))
        // Pending and rejected tasks stay visible to their creator only until the assignment check passes.
        .filter(({ task }) => task.assignmentState === 'assigned' && (task.templateId ?? null) === null);
      const people = await readPeople(tx, db, org, tasks.flatMap(({ task }) => task.assigneeIds));
      const chains = chainsOf(people);
      let n = 0;
      for (const { ref, task } of tasks) {
        const viewerIds = computeViewerIds(task, chains);
        if (sameValue(task.viewerIds, viewerIds)) continue;
        tx.update(ref, { viewerIds });
        n += 1;
      }
      return n;
    });
    if (page.size < size) break;
    last = page.docs[page.size - 1].id;
  }
  log.info('viewer_ids_recomputed', { orgId: org, uid, updated });
  return updated;
}

/** Handler for onDocumentUpdated(orgs/{org}/users/{uid}). */
export async function handleUserUpdated(
  deps: TaskDeps,
  ev: { org: string; uid: string; before: Record<string, unknown> | undefined; after: Record<string, unknown> | undefined },
): Promise<number | null> {
  if (!managerChainChanged(ev.before, ev.after)) return null;
  return recomputeViewerIdsForAssignee(deps, ev.org, ev.uid);
}
