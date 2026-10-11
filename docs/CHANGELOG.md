# Changelog

All notable changes. Versions follow `pubspec.yaml`.

## [Unreleased] - Sprint 2 (tasks, offline, audit)

### Added
- Cloud Functions: `onTaskCreated` assignment check (staff assign themselves, managers their
  reporting tree, verified admins anyone; refusals shown to the creator), `onTaskUpdated`
  (completion with several assignees, checked work, audit), `reassignTask`, `onUserUpdated`
  (`viewerIds` kept in step with reporting changes), server-written audit log for task and user
  changes with "made offline" marking; new error codes `task-not-found`, `task-closed`,
  `assignee-not-allowed`, `assignee-inactive`.
- Rules: checked work (D-06), resubmitting or discarding a refused task, `deleted` flag on every
  task.
- App: My Tasks, Team Tasks and admin task lists (20 per page, live), Kanban board, task detail
  with status actions and reasons, "my part done", confirm or return checked work, cancel,
  delete, reassign, create, edit and resubmit, task activity log, admin audit screen, real sync
  banner, per-task "waiting to sync" marker; EN/SW strings.
- Firestore composite indexes for every new query.

### Fixed
- Audit read rule: a verified admin's list query could include confidential entries because the
  rule used defaults for missing fields. The rule now reads the fields directly (CRITICAL tests).
- Task titles allow 200 characters in the app, as in the rules (KI-10).

## [Unreleased] - Sprint 1 (sign-in, onboarding, organisation)

### Added
- Cloud Functions: `adminUpsertUser`, `deactivateUser`, `sendAdminCode`, `verifyAdminCode`,
  `beforeUserCreated` and `beforeUserSignedIn` blocking functions, MOCK/TEMPORARY e-mail provider
  for the emulators, `bootstrap-org` script, new error codes; unit and emulator integration tests
  (run in CI).
- App: phone and e-mail sign-in, not-invited and deactivated screens, session expiry, onboarding,
  admin code check, departments, users, reporting tree and organisation settings screens, App
  Check (monitor mode), error messages for every new server error; EN/SW widget tests.
- `prod` Firebase alias for `atms-d7f64`.

### Removed
- MOCK developer preview panel.

## [Unreleased] - Sprint 0 (foundation)

### Changed
- Product owner decisions D-01 to D-09 recorded as accepted (8 Oct 2026); Cloud Functions
  default region is now `africa-south1` (D-03).

### Fixed
- Storage rules: an upload over an existing attachment was allowed, because the Storage emulator
  evaluates it as a create. Create now requires that no file exists at that path. Found by the
  first CI run.

### Added
- Product specification (`docs/PRODUCT_SPEC.md`) exported from the ATMS Product Development Document.
- Requirements with IDs, acceptance checklist, backlog with module dependencies, decisions and
  contradictions, architecture (schema, security model, navigation map), testing strategy,
  development and release guides.
- Flutter project (`atms`): folder structure, Riverpod, go_router with role guards, Material 3
  theme, English and Kiswahili localisation, friendly error mapping, pagination helper, sync
  banner, initial screens for every V1 area.
- Cloud Functions project (TypeScript, Jest): data model types, error codes, session and admin
  second-factor checks, log redaction, SMS provider interface with an emulator-only mock.
- Firestore and Storage Security Rules (default deny, server-only workflow state, confidential
  access, 30/7-day sessions, admin second factor) with emulator tests.
- Firestore indexes, emulator configuration, GitHub Actions CI.
