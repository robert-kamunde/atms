# Project status

**Current sprint:** Sprint 2 (tasks, offline, audit), built; in review
**Current milestone:** Sprint 1 PR #2 and Sprint 2 PR #3 (stacked on #2) open on robert-kamunde/atms
**Last updated:** 10 Oct 2026

## Completed
- Sprint 0 foundation (see CHANGELOG): specs, rules, app and functions skeletons, CI.
- Decisions D-01 to D-09 accepted (8 Oct 2026); Firebase project `atms-d7f64` created on Blaze in
  `africa-south1` with Identity Platform, added as the `prod` alias.
- Sprint 1 server: `adminUpsertUser` (reporting loops refused, `managerChain` recomputed for
  everyone below, invitation SMS), `deactivateUser` (sign-in tokens revoked, open tasks flagged),
  admin e-mail code (`sendAdminCode`, `verifyAdminCode`), blocking functions refusing unknown and
  deactivated accounts, `bootstrap-org` script. Interface in `SPRINT1_CONTRACT.md`.
- Sprint 1 app: phone sign-in with code, e-mail fallback with reset, not-invited and deactivated
  screens, session expiry (30/7 days), onboarding (language, consent, notifications), admin code
  check before admin screens, departments, users, reporting tree and organisation settings,
  App Check in monitor mode. Developer preview panel removed.
- Sprint 2 server: assignment check for new tasks (A-01), completion with several assignees,
  checked work (D-06), `reassignTask`, `viewerIds` upkeep, audit log for task and user changes.
  Interface in `SPRINT2_CONTRACT.md`.
- Sprint 2 app: live My Tasks, Team Tasks and admin lists, Kanban board, task detail with every
  action, create/edit/resubmit, activity log, admin audit screen, sync banner.
- Connected debug build for atms-d7f64 in CI (`atms-connected-debug-apk`, A-33).

## In progress
- Review of PR #2 (Sprint 1) and PR #3 (Sprint 2).

## Next
- First deploy of rules, indexes and functions to atms-d7f64, and `bootstrap-org` (waits for
  Robert's go-ahead); then the phone checks (AC-4.1-*, AC-4.3-1/2, AC-4.9-1/2).
- Sprint 3: workflow engine.

## Known bugs
- None found. Limitations are in `KNOWN_ISSUES.md`.

## Blocked
- Admin second factor and invitation SMS in the real project: need the email service (D-08) and
  SMS provider (D-09) accounts (KI-6).

## Technical debt
- Kiswahili review (KI-4), FCM token registration (Sprint 4), `jose` test stub (KI-13).

## Architecture decisions
- Server-authoritative design: the app writes only plain fields; workflow state, visibility,
  escalation, assignment, audit, counters and notifications are Cloud Functions only.
- Workflow moves are transition requests processed in one Firestore transaction (exactly one move).
- Visibility through server-maintained `viewerIds` and `managerChain`.
- Offline task creation is checked by the server before others can see it (DECISIONS A-01).
- Contact details and push tokens kept out of the readable user document (A-12).
- Admin powers require a second-factor claim; admins without it have staff visibility.
- Full list: `ARCHITECTURE.md` and `DECISIONS.md`.

## Acceptance criteria
- Passed: 2 module criteria (AC-4.2-2, AC-4.11-2) plus 7 Sprint 1 checks and 8 Sprint 2 checks.
- Failed: 0
- Blocked: 0
- Not tested: the rest; the phone checks need the first deploy to atms-d7f64.

## Test results (10 Oct 2026, this environment)
| Suite | Result |
| --- | --- |
| Functions unit (Jest) | 80 of 80 pass |
| Functions integration (Auth + Firestore emulators) | 65 of 65 pass |
| Security Rules (Firestore + Storage emulators) | 140 of 142 pass; the 2 Storage cases blocked here pass in CI (KI-1) |
| Functions typecheck and build | Clean |
| Flutter format / analyze | Clean / no issues |
| Flutter tests | 423 of 423 pass |
| Android build | CI (debug APK and connected debug APK) |
