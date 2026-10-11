# Project status

**Current sprint:** Sprint 1 (sign-in, onboarding, organisation), built; in review
**Current milestone:** Sprint 1 PR open on robert-kamunde/atms
**Last updated:** 8 Oct 2026

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

## In progress
- Sprint 1 PR review and CI.

## Next
- Connected build against atms-d7f64 once `google-services.json` arrives (KI-5).
- Sprint 2: tasks, offline, audit foundation.

## Known bugs
- None found. Limitations are in `KNOWN_ISSUES.md`.

## Blocked
- Admin second factor and invitation SMS in the real project: need the email service (D-08) and
  SMS provider (D-09) accounts (KI-6).
- Connected Android build: needs `google-services.json` (KI-5).

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
- Passed: 1 module criterion (AC-4.2-2) plus 7 Sprint 1 checks (S1-1 to S1-7).
- Failed: 0
- Blocked: 0
- Not tested: the rest; AC-4.1-1/2/3 and AC-4.2-1 need a connected build on a phone (KI-5).

## Test results (8 Oct 2026, this environment)
| Suite | Result |
| --- | --- |
| Functions unit (Jest) | 53 of 53 pass |
| Functions integration (Auth + Firestore emulators) | 33 of 33 pass |
| Security Rules (Firestore + Storage emulators) | 90 of 92 pass; the 2 Storage cases blocked here pass in CI (KI-1) |
| Functions typecheck and build | Clean |
| Flutter format / analyze | Clean / no issues |
| Flutter tests | 286 of 286 pass |
| Android build | CI |
