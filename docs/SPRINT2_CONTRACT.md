# Sprint 2 interface contract (backend <-> app): tasks, offline, audit

Read with docs/PRODUCT_SPEC.md 4.3, 4.9, 4.11, DECISIONS A-01, A-02, A-15, D-06, and
SPRINT1_CONTRACT.md (error convention, region, App Check monitor mode).

## Task statuses (D-06 decided)

`todo`, `in_progress`, `blocked`, `awaiting_check`, `done`, `cancelled`.

- New task field `needsCheck: boolean` (default false), set by the creator on create (and editable
  by the creator while the task is open). When true, an assignee's "Done" moves the task to
  `awaiting_check` instead of `done`; the creator then confirms (`awaiting_check -> done`) or
  returns it with a reason (`awaiting_check -> in_progress`, `returnReason` required).
- With several assignees and `completionMode: 'all'`, each assignee adds themselves to
  `completedByIds` (existing rule). The server sets `done` (or `awaiting_check` if `needsCheck`)
  once every current assignee is in `completedByIds`.
- Blocked and Cancelled need a reason (existing rules). `cancelled` and `done` are final for simple
  tasks.
- The app writes status changes directly to Firestore (works offline); rules enforce who may make
  each transition. Workflow tasks (`templateId != null`) are not touched in Sprint 2.

## Task creation (A-01, "assigned when online")

The app creates the task exactly as the current create rule requires (plus `needsCheck`), with
`assignmentState: 'pending'` and `viewerIds: [creator]`. The `onTaskCreated` trigger then:

- checks the creator may assign each assignee: staff only themselves; managers themselves and
  anyone with the manager in their `managerChain`; admins anyone in the org, but only if the admin
  had a valid second factor when the task was created (see "Admin verification record");
- checks every assignee and participant is an active user of the org and the department exists
  and is active;
- on success sets `assignmentState: 'assigned'`, `viewerIds`, and writes the `created` audit entry;
- on failure sets `assignmentState: 'rejected'` and `assignmentError: <ErrorCode>` (e.g.
  `assignee-not-allowed`, `assignee-inactive`, `department-invalid`); the creator alone still sees it
  and the app shows the reason with options to edit or delete.

`viewerIds` = creator + assignees + participants, plus, for non-confidential tasks, every
assignee's `managerChain`. Confidential tasks: creator + assignees + participants only (people with
confidential access for the department read them through the rules).

## Admin verification record

`verifyAdminCode` additionally writes `orgs/{org}/secure/adminVerification/{uid}` =
`{ verifiedUntilMs }`, so triggers (which cannot see custom claims) can check an admin's second
factor at the time of an action.

> Backend note: `orgs/{org}/secure/adminVerification/{uid}` is a collection path (five segments),
> so it cannot hold a document. The record is stored at
> `orgs/{org}/secure/adminVerification/admins/{uid}` instead (same fix as `adminCodes` in
> Sprint 1). Server-only, covered by the `secure/{document=**}` deny rule; the app never reads it.

## Callables (new)

| Name | Caller | Input | Output |
| --- | --- | --- | --- |
| `reassignTask` | creator or manager above every current and new assignee; verified admin for any non-confidential task | `{ taskId, assigneeIds: string[] }` (1-50) | `{ ok: true }` |
| `restoreTask` | not in scope; do not build | | |

`reassignTask`: simple open tasks only; checks the same assignment rule as creation for the new
assignees; resets `completedByIds` to the intersection with the new assignees; clears
`reassignmentNeeded`/`reassignmentReason`; recomputes `viewerIds`; writes a `reassigned` audit entry.
Errors: `task-not-found` (also for tasks the caller cannot read), `task-closed`,
`assignee-not-allowed`, `assignee-inactive`, `validation`.

## Audit (PDD 4.11, A-15)

`orgs/{org}/audit/{entryId}`: `{ taskId, actorId, action, before, after, at, madeOffline,
viewerIds, confidential }`. Written only by the server, exactly one entry per action, idempotent on
trigger retries (entry id derived from the trigger event id plus action).

Actions written in Sprint 2: `task_created`, `task_assigned` (pending -> assigned), `task_rejected`
(assignment refused), `task_reassigned`, `status_changed`, `deadline_changed`, `task_edited`
(title/description/priority), `task_cancelled`, `task_deleted`, `task_completed_by` (one assignee
of several finished), `check_returned`, `user_added`, `user_updated`, `user_deactivated`
(taskId null, viewerIds [] so only verified admins read them).

`before`/`after` hold only the changed fields. `madeOffline` is true when the write carried a
`clientUpdatedAt` more than 60 seconds older than the server's `updatedAt`. Confidential tasks'
audit entries never contain the title or description in `before`/`after` beyond what the task's
viewers can already read (they are readable only by the same viewerIds).

## Visibility upkeep

When a user's `managerChain` changes, a trigger recomputes `viewerIds` for every task (open or
closed) where they are an assignee, in pages of at most 200, so managers see their new team's
history.

## Fields added to tasks in Sprint 2

`needsCheck` (creator), `returnReason` (creator, on return), `assignmentError` (server).

## App queries (indexes are the app's responsibility in firestore.indexes.json)

- My Tasks: `assigneeIds array-contains me`, open statuses, ordered by `deadline`, 20 per page.
- Team Tasks (managers/admins): `viewerIds array-contains me` (admins: all non-confidential tasks
  of the org via the rules' admin branch), with filters status, priority, assignee, department, due
  date, ordered by `deadline`, 20 per page.
- Task detail: the task plus its audit entries `where taskId == id` ordered by `at` desc, 20 per page.
