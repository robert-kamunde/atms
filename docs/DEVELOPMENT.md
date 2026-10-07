# Development guide

## Prerequisites

- Flutter stable (3.47 or newer) with the Android SDK; Xcode on a Mac for iOS.
- Node.js 22 and `npm install -g firebase-tools`.
- Java 21 for the Firebase emulators.

## First run

```bash
git clone <repo> && cd atms-app
flutter pub get
cd functions && npm ci && cd ..
firebase emulators:start --project demo-atms     # Auth 9099, Firestore 8080, Functions 5001, Storage 9199, UI 4000
flutter run --dart-define=USE_FIREBASE_EMULATOR=true --dart-define=FIREBASE_PROJECT_ID=demo-atms \
  --dart-define=FIREBASE_API_KEY=demo --dart-define=FIREBASE_APP_ID=1:000:android:000 \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=000
```

Without Firebase values the app opens on a "not configured" screen instead of crashing.
Real project keys are passed with `--dart-define` (or a `--dart-define-from-file` that is not
committed); `google-services.json` and `GoogleService-Info.plist` are git-ignored.

## Conventions

- Feature order (MI 39): data model, permissions, backend, rules, backend tests, repository,
  Riverpod, UI, localisation, offline, tests, docs, changelog, acceptance.
- No user-facing text in Dart code: add keys to `lib/core/localization/arb/app_en.arb` and
  `app_sw.arb` (a test fails on hardcoded strings and on missing keys). Mark uncertain Kiswahili
  with `SW_REVIEW` in the key's description.
- Never show a raw Firebase error: map it to an `AppFailure` and its translated message.
- Lists use the pagination helper (20 per page); never query a whole collection.
- The app never writes server-only fields (see ARCHITECTURE.md, Security model). If a feature
  seems to need it, the change belongs in a Cloud Function.
- Logs never contain task titles, comment text, phone numbers or emails.
- Temporary stand-ins carry a `// MOCK/TEMPORARY:` comment and an entry in KNOWN_ISSUES.md.
- Commits are small and conventional: `feat:`, `fix:`, `test:`, `docs:`, `chore:`, `ci:`.
- Update CHANGELOG.md, ACCEPTANCE.md and PROJECT_STATUS.md with each meaningful change.
