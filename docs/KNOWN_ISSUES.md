# Known issues

| ID | Issue | Impact | Plan |
| --- | --- | --- | --- |
| KI-1 | Two Storage rules tests ("a task viewer uploads a photo", "CRITICAL: confidential attachments are unreadable without access") fail in the development sandbox: the Storage emulator's cross-service Firestore lookups are routed through the sandbox's network proxy and refused. The denied cases in the same suite pass. | None on the app; local runs only | Both pass in GitHub Actions CI (first run, 8 Oct 2026). CI is the reference for these two tests. |
| KI-2 | The sandbox cannot build Android. | None | Resolved: CI builds the debug APK on every push (first build 8 Oct 2026). |
| KI-3 | `EmulatorSmsProvider` is MOCK/TEMPORARY: it only records messages, and refuses to run against a non-emulator project. | No real SMS | Replaced by the chosen provider in Sprint 4 (D-09). |
| KI-4 | Kiswahili strings have not been reviewed by a native speaker. Strings marked `SW_REVIEW` (70 in the app, plus the invitation SMS and admin-code e-mail texts in functions) are the least certain; the consent text and the top-person warning matter most. | Wording may be unnatural | Review in Sprint 6 (PDD 7). |
| KI-5 | The app is not yet built against atms-d7f64: it needs the Android app's `google-services.json` values as build settings. | Cannot install a connected build | Requested from Robert (8 Oct 2026). |
| KI-6 | The admin second factor (Sprint 1) e-mails a code, but outside `demo-` projects the e-mail and SMS providers refuse to send (`provider-unavailable`) until D-08 and D-09 are contracted. In atms-d7f64 no admin can pass the second factor and no invitation SMS is sent (the user is still created; the failure is logged). | Admins have staff-level access in the real project | Needs the email service (D-08); intended, admin security is not weakened. |
| KI-7 | Developer preview buttons. | None | Resolved in Sprint 1: removed. |
| KI-8 | The app connects the Auth, Firestore and Functions emulators; Storage needs `firebase_storage`, added in Sprint 5. A physical phone needs `FIREBASE_EMULATOR_HOST`. | Local development only | Sprint 5. |
| KI-9 | The sync banner stays hidden: its Firestore-backed source is a Sprint 2 item, and showing "All changes saved" without checking would be false. | No offline indicator yet | Sprint 2. |
| KI-10 | Task form limits titles to 120 characters; the rules allow 200. | None (the app is stricter) | Align when the task module ships in Sprint 2. |
| KI-11 | Flutter 3.47 writes generated localisation files into `lib/core/localization/generated/`; they are committed so a fresh checkout analyses cleanly. | Must regenerate after editing ARB files (`flutter gen-l10n`, also run by `flutter pub get`) | None. |
| KI-12 | Each real project needs `APP_DOWNLOAD_URL` in `functions/.env.<projectId>` for the invitation SMS. `functions/.env.demo-atms` has a placeholder. | Invitation link missing | Set before the first deploy to atms-d7f64. |
| KI-13 | The functions integration tests replace the ESM-only `jose` package (pulled in by firebase-admin/auth) with a stub (`functions/test/stubs/jose.js`); the tests never verify tokens. | Token verification is not exercised by these tests | Revisit when ts-jest supports ESM cleanly. |
| KI-14 | Adding, changing and deactivating users writes no audit entries yet. | Audit gap for Sprint 1 actions | The audit writer arrives in Sprint 2 and will cover these. |
| KI-15 | Choosing "Not now" for notifications asks again on the next cold start, because the rules allow no field to remember the choice. | One extra prompt per start | Revisit with push registration in Sprint 4 (FCM token registration is also a Sprint 4 TODO). |
| KI-16 | On an offline cold start after the ID token has expired, the app waits for a connection before it can read the claims. | Admin/session checks wait for network | Accepted; tasks remain cached. |
| KI-17 | The user list search covers only people already loaded (20 per page). | Searching a large organisation needs scrolling first | Server-side search if the pilot needs it. |
| KI-18 | Workflow error codes (`not-step-owner` and others) are not mapped to friendly messages yet; they show the generic message. | Sprint 3 only | Map in Sprint 3. |
