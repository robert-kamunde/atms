# Changelog

All notable changes. Versions follow `pubspec.yaml`.

## [Unreleased] - Sprint 0 (foundation)

### Changed
- Product owner decisions D-01 to D-09 recorded as accepted (8 Oct 2026); Cloud Functions
  default region is now `africa-south1` (D-03).

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
