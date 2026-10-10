# tasks (spec 4.3)
My Tasks, Team Tasks (list and board), task create/edit/resubmit, and task detail with role-based actions and the activity log. Sprint 2.

- `domain/task_policy.dart` mirrors `firestore.rules` for UI decisions only (which buttons and which assignees to offer). The rules and the server stay the real check.
- `data/task_write_maps.dart` holds the exact field set of every client write. Each update also sets `updatedAt` (server time), `updatedBy` and `clientUpdatedAt` (phone time).
- `data/firestore_task_repository.dart`: lists use `FirestorePaginatedQuery` (20 per page) with the clauses the read rule needs (`deleted == false` plus viewer, assignee or admin branch). Each query has a composite index in `firestore.indexes.json`.
- Every action except reassign works offline (`awaitOfflineCapableWrite`). Reassign is the `reassignTask` callable and needs a connection.
