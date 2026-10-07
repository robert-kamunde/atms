# Known issues

| ID | Issue | Impact | Plan |
| --- | --- | --- | --- |
| KI-1 | Two Storage rules tests ("a task viewer uploads a photo", "CRITICAL: confidential attachments are unreadable without access") fail in the development sandbox: the Storage emulator's cross-service Firestore lookups are routed through the sandbox's network proxy and refused. The denied cases in the same suite pass. | None on the app; the allowed Storage paths are not yet proven by a test run | Must pass in GitHub Actions CI, which has no proxy. Not marked PASS until then. |
| KI-2 | No Android build has been produced yet: the sandbox cannot download the Android SDK. | No APK from Sprint 0 until CI runs | CI workflow builds the debug APK once the GitHub repository exists. |
| KI-3 | `EmulatorSmsProvider` is MOCK/TEMPORARY: it only records messages, and refuses to run against a non-emulator project. | No real SMS | Replaced by the chosen provider in Sprint 4 (D-09). |
| KI-4 | Kiswahili strings have not been reviewed by a native speaker. Strings marked `SW_REVIEW` are the least certain. | Wording may be unnatural | Review in Sprint 6 (PDD 7). |
| KI-5 | No Firebase project exists yet; the app runs only against the emulators or shows "not configured". | Cannot install a connected build | Needs Robert's Google account and D-03. |
| KI-6 | Admin powers depend on the `adminVerifiedUntil` claim, which nothing sets until the second factor is built (Sprint 1, D-01). | Until then admins have staff-level visibility in a real project | Intended: admin security is not weakened for development. |
