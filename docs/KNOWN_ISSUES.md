# Known issues

| ID | Issue | Impact | Plan |
| --- | --- | --- | --- |
| KI-1 | Two Storage rules tests ("a task viewer uploads a photo", "CRITICAL: confidential attachments are unreadable without access") fail in the development sandbox: the Storage emulator's cross-service Firestore lookups are routed through the sandbox's network proxy and refused. The denied cases in the same suite pass. | None on the app; the allowed Storage paths are not yet proven by a test run | Must pass in GitHub Actions CI, which has no proxy. Not marked PASS until then. |
| KI-2 | No Android build has been produced yet: the sandbox cannot download the Android SDK. | No APK from Sprint 0 until CI runs | CI workflow builds the debug APK once the GitHub repository exists. |
| KI-3 | `EmulatorSmsProvider` is MOCK/TEMPORARY: it only records messages, and refuses to run against a non-emulator project. | No real SMS | Replaced by the chosen provider in Sprint 4 (D-09). |
| KI-4 | Kiswahili strings have not been reviewed by a native speaker. Strings marked `SW_REVIEW` are the least certain. | Wording may be unnatural | Review in Sprint 6 (PDD 7). |
| KI-5 | No Firebase project exists yet; the app runs only against the emulators or shows "not configured". | Cannot install a connected build | Needs Robert's Google account and D-03. |
| KI-6 | Admin powers depend on the `adminVerifiedUntil` claim, which nothing sets until the second factor is built (Sprint 1, D-01). | Until then admins have staff-level visibility in a real project | Intended: admin security is not weakened for development. |
| KI-7 | Developer preview buttons ("Open as Staff/Manager/Admin") on the sign-in and not-configured screens are MOCK/TEMPORARY. They appear only in debug builds with `ATMS_ENV=dev` and open empty screens without signing in. | None in release builds | Remove in Sprint 1 once emulator sign-in works. |
| KI-8 | The app connects only the Auth and Firestore emulators; Functions and Storage need `cloud_functions` and `firebase_storage`, added when first used (Sprints 1 and 5). A physical phone needs `FIREBASE_EMULATOR_HOST`. | Local development only | Add the packages in the sprint that needs them. |
| KI-9 | The sync banner stays hidden: its Firestore-backed source is a Sprint 2 item, and showing "All changes saved" without checking would be false. | No offline indicator yet | Sprint 2. |
| KI-10 | Task form limits titles to 120 characters; the rules allow 200. | None (the app is stricter) | Align when the task module ships in Sprint 2. |
| KI-11 | Flutter 3.47 writes generated localisation files into `lib/core/localization/generated/`; they are committed so a fresh checkout analyses cleanly. | Must regenerate after editing ARB files (`flutter gen-l10n`, also run by `flutter pub get`) | None. |
