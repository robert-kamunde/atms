# Testing strategy

Nothing is called done until it is tested (MI 42). The acceptance status of every PDD "Done when"
item lives in [ACCEPTANCE.md](ACCEPTANCE.md).

## Test layers

| Layer | Tool | Where | What it covers | Runs in |
| --- | --- | --- | --- | --- |
| Backend unit | Jest + ts-jest | `functions/test/unit` | Pure logic: transition decisions, step owner resolution, deadline and working-hours maths, reminder and escalation timing, notification channel choice, safe message text, session checks, log redaction | `npm run test:unit`, CI |
| Security Rules | Jest + `@firebase/rules-unit-testing` + Firestore and Storage emulators | `functions/test/rules` | Every role (staff, manager, admin with and without second factor, confidential-access holder, deactivated user, other organisation, signed out) against normal, confidential, other-department and other-user tasks, comments, attachments, audit, notifications, stats, users, templates, settings; allowed and denied | `npm run test:rules`, CI |
| Backend integration | Jest + Functions, Firestore and Auth emulators | `functions/test/integration` (Sprint 1 on) | Triggers and callables end to end: transition processor in a transaction, concurrent approvals, idempotent retries, audit entries, counters | CI |
| Flutter unit | `flutter test` | `test/` | Models and their Firestore maps (server-only fields never serialised by the app), session policy, error mapping (no raw Firebase errors), filters, pagination | CI |
| Widget | `flutter test` | `test/` | Main screens render and respond in English and Kiswahili; validation messages; router guards by role; no hardcoded strings; ARB key parity | CI |
| Integration (app) | `integration_test` on an Android emulator + Firebase emulators | `integration_test/` | The five prototype scenarios (E2E-1 to E2E-5) | CI from Sprint 3 (needs an Android emulator runner) |
| Offline | Scripted + manual | `integration_test/offline_*` and a written script | Flight mode, create/status/comment/approval offline, reconnect, restart while offline, duplicate sync, conflicts, full-day offline on a real low-end phone, sync within 10 s | Sprint 2 on; manual run each sprint |
| Load | Node script against the emulator, then staging | `tools/load/` (Sprint 6) | 1,000 users, 50,000 tasks per organisation: list query latency, rule evaluation, scheduler job duration | Sprint 6 |
| Performance | Device timing | Real mid-range and low-end Android phones, 3G throttling | Screens under 2 s, APK under 25 MB | Sprint 6-7 |
| Usability | Timed tasks, SUS questionnaire | Pilot users | Task in under 30 s, first task in under 2 min, SUS 70+ | Sprint 7 |

## Rules for writing tests

- Security tests prove both directions: each allowed case has a denied neighbour.
- Confidentiality tests are named `CRITICAL` and must never be skipped.
- Time-dependent backend logic takes a clock argument; tests never sleep.
- Concurrency tests fire real parallel requests at the emulator and assert exactly one
  `applied` result and one audit entry.
- Widget tests pump every main screen twice, `Locale('en')` and `Locale('sw')`.
- Tests use the prototype's people (Neema, John, Asha, Grace, Baraka, Rehema, Idrisa) so
  scenarios read the same everywhere.
- Mocks are labelled `MOCK/TEMPORARY` in code. Mocks never replace a production path; the
  emulator SMS provider refuses to run against a non-`demo-` project.

## Running locally

```bash
# Backend
cd functions && npm ci
npm run lint && npm run test:unit
npm run test:rules            # starts Firestore and Storage emulators (needs Java 21+)

# App
flutter pub get
flutter analyze
flutter test
```

## Current results

See [PROJECT_STATUS.md](PROJECT_STATUS.md).
