# Decisions, contradictions and ambiguities

The master instructions say: when a requirement is unclear and the answer affects security, data
integrity, workflow state or extensibility, stop and surface it; otherwise choose the simplest
option and document it. This file holds both kinds.

- **Product owner decisions** were surfaced for Robert; all nine were decided on 8 Oct 2026.
- **Open** decisions (none at present) need the product owner. Work on the affected feature waits,
  or continues on the stated default where that default is easy to change later.
- **Defaults taken** are minor or reversible choices made to keep going.

## Product owner decisions (decided 8 Oct 2026)

Robert accepted every recommendation below ("answers on open decisions: agree", 8 Oct 2026). The
**Recommendation** column is now the decision.

| ID | Question | Why it matters | Options | Recommendation (decided) | Affects |
| --- | --- | --- | --- | --- | --- |
| D-01 | How should the admin second factor ("email code") work? | Firebase's built-in multi-factor sign-in supports SMS and authenticator apps (TOTP), not email codes. An email code needs our own Cloud Function plus an email-sending service. | (a) Email code: a Cloud Function emails a 6-digit code through an email service (for example SendGrid or Mailgun) and sets the `adminVerifiedUntil` claim. (b) Authenticator app (TOTP), supported natively. | (a), because it is what the PDD specifies. It needs an email service account, which D-08 can share. | Sprint 1 admin sign-in |
| D-02 | Upgrade Firebase Authentication to Identity Platform? | Without it, Firebase creates an account for any phone number that completes the code. Our rules then refuse that account everything and the app shows "Ask your administrator to add you", but the code SMS has already been paid for and an empty account exists. Identity Platform adds "blocking functions" that refuse unknown numbers before the account is created and can refuse deactivated users at sign-in. | (a) Upgrade (free up to a monthly user allowance; phone SMS billed either way). (b) Stay on basic Auth, rely on rules and a nightly clean-up of stray accounts. | (a) | Sprint 1 sign-in |
| D-03 | Where should the data live (Firestore region)? | Tanzania PDPA 2022 governs transferring personal data outside Tanzania. Google Cloud has no Tanzanian region; the nearest is Johannesburg (`africa-south1`). The Firestore location cannot be changed after creation. | `africa-south1` (Johannesburg), or `europe-west1` (Belgium) | `africa-south1`, subject to a check of PDPA cross-border transfer requirements by the pilot organisation. Decided; the Firestore location must be set to `africa-south1` when the database is created | Creating the Firebase project |
| D-04 | App Check: enforce, or monitor only at first? | App Check on Android uses Play Integrity, which needs Google Play services. Phones without them (for example recent Huawei models, common in Tanzania) would be locked out if App Check is enforced. | (a) Enforce from day one. (b) Monitor in the pilot, then enforce once the share of failing devices is known. | (b), with the Security Rules (which do not depend on App Check) as the real protection | Sprint 1 setup |
| D-05 | How do "role" steps pick a person, and who may act on them? | The PDD's templates use job titles ("Role: Finance Officer", "Role: Director"), which are not the Admin/Manager/Staff roles, and says "the step goes to the one with the fewest open tasks, and any of them can pick it up". | Add a `jobRole` field to users. The server assigns the step to the eligible person with the fewest open tasks; any active person with that job role may submit, approve or reject it (the server accepts them as owner). If nobody holds the job role, the step is not moved, the task is flagged and admins are notified. | As described | Sprint 3 workflow engine |
| D-06 | What does "Done (or creator, if the creator requires a check)" mean? | PDD 4.3 mentions a creator check on simple tasks, but the data model has no field for it and no screen describes it. | (a) Add a "needs my check" option: the assignee's Done becomes "Waiting for check" until the creator confirms. (b) Leave it out of V1 and remove the phrase from the PDD. | (a), because the PDD specifies it and the instructions forbid dropping specified behaviour. It adds a `needsCheck` flag and a "Waiting for check" state, both documented deviations | Sprint 2 task statuses |
| D-07 | With working hours on, how are 24 h and 48 h escalation delays counted? | PDD 4.2 says deadlines and escalation "count working hours only" when the setting is on; PDD 4.5 says reminders falling outside working hours are held until 08:00. These give different escalation times. | (a) Count elapsed working hours (24 working hours = 3 working days of 8 hours). (b) Count calendar hours and hold any send that falls outside working hours until 08:00. | (a) for escalation and step time limits, plus (b)'s holding rule for every send | Sprint 4 escalation |
| D-08 | Which email service sends optional report emails (and admin codes)? | The master instructions exclude "external integrations" but require optional report email. An email service is the minimum needed. | SendGrid, Mailgun, Amazon SES, or the organisation's own SMTP | One transactional email service, shared with D-01 | Sprint 6 reports |
| D-09 | Which SMS provider, and the sender ID? | Africa's Talking and Beem both work in Tanzania; sender ID registration with TCRA takes time. | Africa's Talking or Beem | Whichever the pilot organisation can contract; start sender ID registration now | Sprint 4 SMS |

## Defaults taken (documented, easy to revisit)

| ID | Topic | Default | Reason |
| --- | --- | --- | --- |
| A-01 | Task creation offline | The app writes the task as `assignmentState: pending` with only the creator able to see it. A Cloud Function checks the creator may assign those people (staff only themselves, managers their reporting tree, admins anyone), fills `viewerIds` and marks it `assigned`, or marks it `rejected` with a reason the creator sees. | PDD 4.9 says new tasks are "assigned when online"; the Security Rules cannot check reporting trees for a list of assignees. |
| A-02 | Several assignees | Fields `completionMode` (`all` default, or `any`) and `completedByIds`. Each assignee adds only themselves; the server marks the task Done when everyone has. | PDD 4.3.4 and MI 9 require it; the PDD data model has no field for it. |
| A-03 | Manager visibility | Managers see their reporting tree (everyone with them in `managerChain`). | PDD 4.8 defines it this way; the matrix's "own department" is covered when department staff report to the head, which ORG-2 sets up. |
| A-04 | Reject at an approval step | Goes to the previous step; at step 2 that is the starter's step 1. Reject is offered only on approval steps; non-approval steps have Submit. | PDD 4.4.5. |
| A-05 | Workflow deadline | The overall deadline is the start time plus the sum of the step time limits; each step has its own `stepDeadline`, which reminders and escalation use. | PDD 4.4 ("the template's total time sets the overall deadline"). |
| A-06 | Workflow cancel and reassign | Done through Cloud Functions (callable), not transition requests, because the PDD's request actions are only submit, approve, reject and send back. They need a connection. | Keeps the PDD's `action` list unchanged. |
| A-07 | Escalation chain | Uses the assignee's (or step owner's) `managerChain`. Inactive people are skipped. If there is no one above, the task appears in the admin report only. | PDD 4.5; avoids a dead end. |
| A-08 | SMS cap unit | Monthly cap in Tanzanian shillings, using the cost the provider reports; when the provider reports no cost, a configured price per message. | PDD 7 costs are per message; the admin sets a money cap. |
| A-09 | Comment removal | Only the author removes their comment. | PDD 4.7 is silent on moderators; removal is logged either way. |
| A-10 | Offline comment edits after 15 minutes | An edit made offline that reaches the server after the 15-minute window is refused and the app says the edit window has passed. | The server clock is the only trustworthy clock. |
| A-11 | Sign-in code SMS | Sent by Firebase Authentication, billed by Google, and not counted against the ATMS SMS cap. | Firebase Phone Auth sends its own codes. |
| A-12 | Contact details and push tokens | Moved from the user document to `users/{uid}/private/contact` and `private/devices`. | Every member must read colleagues' names for assignee pickers; they must not read phone numbers or push tokens (PDPA data minimisation). |
| A-13 | Department deletion | Departments are deactivated, not deleted, so old tasks keep their department. | Data integrity. |
| A-14 | Templates | Saved through a Cloud Function that bumps `version` and stores every version under `templates/{tpl}/versions/{v}`. Running tasks read their pinned version. | WF-10, and the template change must be audited by the server. |
| A-15 | Audit entries | Carry a copy of the task's `viewerIds` and `confidential` flag so the rules can enforce who reads them. | AUD-5 and CONF-5. |
| A-16 | Escalation levels | `escalationMaxLevel` per organisation, default 2. | PDD 4.5 "times are configurable per organisation"; the prototype shows a 3-level setting as a possible change. |
| A-17 | "Not found" for confidential tasks | Firestore returns "permission denied"; the app shows the same "not found" message for a denied read and a missing task. | CONF-2; Firestore cannot return "not found" for a denied read. |
| A-18 | App languages before sign-in | English until the user picks a language; the phone's language is offered first if it is Swahili. | AUTH-6. |

## Contradictions found between the documents

| ID | Where | Conflict | Resolution |
| --- | --- | --- | --- |
| C-01 | MI 38 vs MI 39 | Sprint 5 lists "Security rules", but MI 39 requires rules before UI for every feature. | Rules for each feature are written in that feature's sprint; the baseline rules exist from Sprint 0. Sprint 5 completes confidential creation and attachment flows and runs the full rules review. |
| C-02 | PDD 2 matrix vs PDD 4.8 | "Own department and reports below" vs "everyone who reports to them". | A-03. |
| C-03 | PDD 4.2 vs PDD 4.5 | Working-hours counting vs holding sends until 08:00. | D-07 (decided). |
| C-04 | PDD 4.10 vs MI 25 | MI adds "completion rate" to report contents. | Include it; MI is the newer client instruction and it does not conflict. |
| C-05 | MI 2 vs MI 25 | "No external integrations" vs "optional email". | D-08 (decided). |
| C-06 | PDD 7 Sprint 0 vs MI 38 Sprint 0 | PDD Sprint 0 includes interviews and a baseline survey; MI Sprint 0 is technical. | Interviews and the survey are the product owner's work; tracked in PROJECT_STATUS as outside engineering. |
| C-07 | PDD 4.6 table vs MI 16 | MI lists "sign-in codes" as a notification event; those codes come from Firebase Authentication, not the ATMS notification system. | A-11. |
