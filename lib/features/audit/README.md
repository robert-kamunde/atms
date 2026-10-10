# audit (spec 4.11)
Read-only view of the audit log. Only server functions write it. Sprint 2.

- Task activity (task detail): `taskId ==` plus `viewerIds array-contains me`, or `confidential == false` for a verified admin, newest first, 20 per page.
- Organisation log (admin screen): `confidential == false`, newest first, 20 per page.
- `presentation/widgets/activity_tile.dart` turns each entry into a localised sentence (actor, change, time, "made offline" marker).
