# Project status

**Current sprint:** Sprint 0 (foundation), finishing
**Current milestone:** Sprint 0 delivered for review; Sprint 1 waits for the product owner's answers to the open decisions
**Last updated:** 7 Oct 2026

## Completed
- PDD read and exported as `docs/PRODUCT_SPEC.md`.
- Requirements extracted with IDs (`REQUIREMENTS.md`): 11 modules, roles and permission matrix with
  enforcement, security, offline, notification and performance requirements, out-of-scope list.
- Acceptance checklist (`ACCEPTANCE.md`): all 29 PDD "Done when" items, the 5 prototype scenarios
  and 8 quality targets, each with sprint, test and status.
- Backlog by sprint with module dependencies (`BACKLOG.md`).
- Contradictions, ambiguities, open decisions and defaults (`DECISIONS.md`).
- Architecture, Firestore schema with documented deviations, security model, offline design,
  navigation map, environments (`ARCHITECTURE.md`); testing strategy (`TESTING.md`); development,
  release, known issues and changelog docs.
- Firestore and Storage Security Rules (default deny) and indexes; emulator config.
- Security Rules tests: 87 cases over every role and resource, allowed and denied.
- Cloud Functions project (TypeScript, Jest): model types, error codes, session and admin
  second-factor checks, log redaction, SMS provider interface with emulator-only mock.
- Flutter app foundation: specified folder structure, Riverpod, go_router with role guards, theme,
  216 English/Kiswahili strings, friendly error mapping, pagination helper (20 per page), sync banner
  widget, initial screens for every V1 area, Firebase bootstrap with offline persistence and
  emulator support, "not configured" screen.
- Flutter tests: 137 (unit, widget in English and Kiswahili, router guards, ARB parity,
  no-hardcoded-strings scan).
- CI workflow (GitHub Actions): functions lint, build, unit and rules tests; Flutter format, analyze,
  test and debug APK build.
- Screenshots of the initial screens: `atms-app-screens/atms-sprint0-screens.png` in project files.

## In progress
- Nothing; waiting for the product owner.

## Next (Sprint 1, after the decisions)
- `adminUpsertUser` with loop detection and managerChain; deactivation; unknown-number handling;
  admin second factor; invitation SMS; sign-in, onboarding and admin organisation screens.

## Known bugs
- None found. Limitations are in `KNOWN_ISSUES.md`.

## Blocked
- GitHub repository: CI cannot run and no APK can be built until Robert creates an empty
  repository and connects it (the sandbox cannot download the Android SDK).
- Firebase projects (staging, production): need Robert's Google account and decision D-03 (region).
- SMS provider account and sender ID (D-09).
- Two Storage rules tests need CI (KNOWN_ISSUES KI-1).

## Technical debt
- Developer preview buttons (MOCK/TEMPORARY, debug only) to remove in Sprint 1.
- `cloud_functions` and `firebase_storage` packages not yet added to the app (KI-8).
- Kiswahili review pending (36 strings marked SW_REVIEW).

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
- Passed: 0
- Failed: 0
- Blocked: 0
- Not tested: 42 (29 module criteria, 5 scenarios, 8 quality targets). The rules tests for
  AC-4.8-1 (confidential reads) and AC-4.11-1/2 (audit immutability) exist and pass in the
  emulator; the criteria are marked PASS only when their modules ship.

## Test results (7 Oct 2026, this environment)
| Suite | Result |
| --- | --- |
| Security Rules (Firestore emulator) | 80 of 80 pass |
| Storage rules (Storage emulator) | 5 of 7 pass; 2 blocked by the sandbox proxy (KI-1) |
| Functions unit (Jest) | 7 of 7 pass |
| Functions typecheck and build | Clean |
| Flutter analyze | No issues |
| Flutter tests | 137 of 137 pass |
| Android build | Not run here (KI-2); runs in CI |
