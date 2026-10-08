# Sprint 1 interface contract (backend <-> app)

Region: `africa-south1` (functions/src/shared/config.ts REGION). All callables are
`onCall` v2, `enforceAppCheck: false` (D-04 monitor mode: log when `request.app` is missing,
never reject on it). Errors use `HttpsError` with `details: { code: ErrorCode }` from
functions/src/shared/errors.ts so the app's failure mapper can show a friendly message.

## Callables

| Name | Caller | Input | Output |
| --- | --- | --- | --- |
| `adminUpsertUser` | verified admin (role admin + `adminVerifiedUntil` claim in the future + fresh 7-day session) | `{ uid?: string, name: string, phone: string \| null (E.164, Tanzania +255...), email: string \| null, role: 'admin'\|'manager'\|'staff', deptId: string, supervisorId: string \| null, jobRole: string \| null, language: 'en'\|'sw', confidentialDepts: string[] }` (at least one of phone/email) | `{ uid: string, created: boolean }` |
| `deactivateUser` | verified admin | `{ uid: string }` | `{ flaggedTaskCount: number }` |
| `sendAdminCode` | member with role admin (claim not needed) | `{}` | `{ maskedEmail: string, expiresAt: number (epoch ms) }` |
| `verifyAdminCode` | member with role admin | `{ code: string }` (6 digits) | `{ verifiedUntil: number (epoch ms) }` — the app must then call `getIdToken(true)` |

Rules for `adminUpsertUser`:
- Creates the Firebase Auth user (phone and/or email; email accounts get a random password and
  must use "forgot password" to set one) with custom claim `{ orgId }`; on update, changes the
  Auth phone/email if changed.
- Writes `orgs/{org}/users/{uid}` (public fields) and `orgs/{org}/users/{uid}/private/contact`.
- Every user except the top person (exactly one active user per org may have `supervisorId == null`)
  must have an active supervisor in the same org. Reporting loops are rejected with
  `ErrorCode` for a loop. `managerChain` is recomputed for the user and everyone below them.
- Department must exist and be active.
- Phone numbers and emails are unique per project (Auth enforces it); a clash returns a clear error.
- On create, sends the invitation SMS through `SmsProvider`:
  "You have been added to {org name} on ATMS. Download the app: {APP_DOWNLOAD_URL}" (Kiswahili
  version when language is 'sw'). No task data is ever in it.
- Admins cannot remove their own admin role or deactivate themselves; the last active verified
  admin cannot be demoted.

`deactivateUser`: sets `active: false`, revokes refresh tokens (user is signed out within an hour;
rules refuse them immediately because they check `active`), sets `reassignmentNeeded: true` and
`reassignmentReason: 'user_deactivated'` on their open (not done/cancelled, not deleted) tasks where
they are an assignee, notifies nobody yet (notifications are Sprint 4; leave a TODO hook).
Users whose supervisor is the deactivated person keep that supervisor until an admin changes it;
the user list flags them.

Admin second factor (D-01): 6-digit code, stored only as a salted SHA-256 hash in
`orgs/{org}/secure/adminCodes/{uid}` with expiry 10 minutes, at most 5 verify attempts per code
and at most 5 codes per hour per admin. Sent by email through an `EmailProvider` interface
(emulator-only MOCK/TEMPORARY implementation like the SMS one). On success, sets custom claims
`{ orgId, adminVerifiedUntil: <epoch seconds> }` with verification valid for 12 hours, never past
the 7-day admin session.

## Blocking functions (D-02, Identity Platform)

- `beforeUserCreated`: refuse every account creation from the app. All accounts are created by
  `adminUpsertUser` (Admin SDK creations do not run blocking functions), so an unknown phone
  number is refused before an account exists. Error message key: `not-invited`.
- `beforeUserSignedIn`: refuse if the user's `orgs/{org}/users/{uid}.active` is false.

The app shows the "Ask your administrator to add you" screen for the `not-invited` refusal
(Firebase surfaces it as an auth error whose message contains `not-invited` /
`BLOCKING_FUNCTION_ERROR_RESPONSE`).

## Organisation bootstrap

The first organisation and first admin are created by a one-off Admin SDK script
`functions/scripts/bootstrap-org.ts` (org doc with defaults, one department, one admin user with
phone/email). Departments and organisation settings are then edited by verified admins directly in
Firestore (already allowed by firestore.rules).

## Firestore fields added in Sprint 1

- `users/{uid}`: `reassignmentNeeded` is on tasks, not users. Users gain nothing new.
- `tasks/{task}`: `reassignmentNeeded: boolean`, `reassignmentReason: string` (server-only).
