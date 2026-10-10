# Release process

Status: not yet released. Filled in fully in Sprint 7; Sprint 0 records what is needed.

## Needed before the first installable pilot build

- Firebase projects for staging and production on the Blaze plan, in the region chosen in
  DECISIONS D-03, with a budget alert (PDD 7 suggests USD 10 per month for the pilot).
- Android app registered in each project; App Check with Play Integrity (D-04).
- A release signing key kept outside the repository (Play App Signing recommended).
- Google Play developer account (USD 25 once); iOS later needs an Apple developer account and a Mac.
- SMS provider account and TCRA-registered sender ID (D-09).
- Crashlytics and Analytics enabled; daily Firestore export with 30-day retention.

## Build

```bash
flutter build appbundle --release --dart-define-from-file=env/prod.json   # env files are not committed
cd functions && npm run build && firebase deploy --only functions,firestore,storage --project prod   # alias for atms-d7f64 in .firebaserc
```

Every sprint ends with a working debug APK built by CI (`atms-debug-apk` artifact, not connected).
CI also builds `atms-connected-debug-apk` against atms-d7f64 with the committed DEVELOPMENT key
(DECISIONS A-33); locally:

```bash
flutter build apk --debug --dart-define-from-file=config/firebase/atms-d7f64.json
```

Never sign a Play Store release with `android/dev-signing/`.

## Release checklist

1. All acceptance items for the release are PASS in ACCEPTANCE.md.
2. Rules tests, unit, widget and integration tests green in CI.
3. Known critical bugs: zero (KNOWN_ISSUES.md).
4. CHANGELOG.md updated, version bumped in `pubspec.yaml`.
5. Rules and indexes deployed before the app that needs them.
