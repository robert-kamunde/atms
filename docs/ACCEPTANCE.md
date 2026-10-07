# Acceptance checklist

Every "Done when" item from the PDD (section 4), unchanged in wording, plus the five prototype
scenarios (MI 44) and the quality targets (PDD 6). Status is one of PASS, FAIL, BLOCKED,
NOT TESTED. A feature is not complete while any of its items is not PASS.

Last updated: 7 Oct 2026 (Sprint 0).

## Module criteria

| ID | Criterion (PDD wording) | Sprint | Test | Status |
| --- | --- | --- | --- | --- |
| AC-4.1-1 | A new user can sign in with phone and code and see their tasks. | 1 | Integration (emulator Auth) + device | NOT TESTED |
| AC-4.1-2 | An uninvited number cannot get in. | 1 | Rules test + integration | NOT TESTED |
| AC-4.1-3 | A deactivated user is signed out within 1 hour and their tasks are flagged for reassignment. | 1 | Rules test (deactivated user refused: written) + function test | NOT TESTED |
| AC-4.2-1 | An Admin can set up a 50-person organisation with 5 departments in under 1 hour. | 1 | Timed usability test | NOT TESTED |
| AC-4.2-2 | The reporting tree shows correctly and loops are rejected. | 1 | Jest + widget test | NOT TESTED |
| AC-4.3-1 | A task can be created in under 30 seconds with only the required fields. | 2 | Timed usability test | NOT TESTED |
| AC-4.3-2 | Status changes show for the creator within 5 seconds when both are online. | 2 | Integration timing | NOT TESTED |
| AC-4.3-3 | Filters work by status, priority, assignee, department and due date. | 2 | Widget + repository tests | NOT TESTED |
| AC-4.4-1 | A 5-step template can be built in the app without code. | 3 | Integration | NOT TESTED |
| AC-4.4-2 | Submitting a step assigns the next owner and notifies them within 10 seconds. | 3 | Emulator integration timing | NOT TESTED |
| AC-4.4-3 | Reject and send back return the task to the right step with the comment visible. | 3 | Jest + integration | NOT TESTED |
| AC-4.4-4 | Two approvals of the same step sent at the same time result in exactly one move. | 3 | Jest concurrency test (emulator) | NOT TESTED |
| AC-4.5-1 | Reminders arrive within 15 minutes of the due time. | 4 | Jest with fake clock | NOT TESTED |
| AC-4.5-2 | A task 24 hours overdue reaches the supervisor; at 48 hours, the next level. | 4 | Jest with fake clock | NOT TESTED |
| AC-4.5-3 | No reminder is ever sent twice for the same task and time. | 4 | Jest (repeated job runs) | NOT TESTED |
| AC-4.6-1 | Every event in the table reaches the right channels. | 4 | Jest per event | NOT TESTED |
| AC-4.6-2 | SMS is not sent when the push was opened in time. | 4 | Jest | NOT TESTED |
| AC-4.6-3 | No SMS ever contains a confidential task's title. | 4 | Jest | NOT TESTED |
| AC-4.7-1 | A comment typed offline appears for others after reconnection. | 5 | Offline integration | NOT TESTED |
| AC-4.7-2 | A 4 MB phone photo uploads at under 500 KB. | 5 | Widget/unit test + device | NOT TESTED |
| AC-4.8-1 | A user who is not a participant cannot read a confidential task even with a modified app (tested with the Firebase Emulator). | 0, 5 | Rules tests `CRITICAL: confidential tasks` (12 cases) and Storage `CRITICAL` case | NOT TESTED (Firestore cases pass in the emulator; the Storage allowed-read case is blocked in this sandbox and must pass in CI; will be marked PASS when the confidential feature is complete in Sprint 5) |
| AC-4.8-2 | Confidential titles never appear in push or SMS text. | 4 | Jest | NOT TESTED |
| AC-4.9-1 | A user can work for a full day offline and sync with no lost changes. | 2 | Manual script on a real phone | NOT TESTED |
| AC-4.9-2 | Changes sync within 10 seconds of the connection returning. | 2 | Scripted timing test | NOT TESTED |
| AC-4.9-3 | Conflicting workflow approvals produce one move and a clear message for the other user. | 3 | Jest + offline integration | NOT TESTED |
| AC-4.10-1 | Dashboards load in under 2 seconds on 3G. | 6 | Device timing, throttled | NOT TESTED |
| AC-4.10-2 | Report numbers match a manual count of the same tasks. | 6 | Jest against seeded data | NOT TESTED |
| AC-4.11-1 | Every action in the list creates exactly one entry. | 2-5 | Jest per action | NOT TESTED |
| AC-4.11-2 | An attempt to edit a log entry from the app is refused by the server. | 0 | Rules test `nobody writes audit entries from the app` | NOT TESTED (rules test passes; marked PASS when the audit module ships in Sprint 2) |

## Prototype scenarios as end-to-end tests (MI 44)

| ID | Scenario | Sprint | Status |
| --- | --- | --- | --- |
| E2E-1 | Escalation: Asha's "Purchase 5 laptops" goes overdue, escalates to John, then Neema; notification and SMS visible | 4 | NOT TESTED |
| E2E-2 | Workflow: Asha approves Finance check, Neema Final approval, task moves to Baraka for Procure; reject and send back need comments | 3 | NOT TESTED |
| E2E-3 | Offline conflict: Asha's offline approval is rejected after John's; one transition only | 3 | NOT TESTED |
| E2E-4 | Confidentiality: disciplinary task visible only to authorised people; unauthorised admin cannot see it; title never in notifications or SMS | 5 | NOT TESTED |
| E2E-5 | Roles and languages: staff, manager and admin dashboards; switch English and Kiswahili, every string changes | 6 | NOT TESTED |

## Quality targets (PDD 6, MI 33)

| ID | Target | Sprint | Status |
| --- | --- | --- | --- |
| Q-1 | Main screens under 2 s on mid-range Android over 3G | 6-7 | NOT TESTED |
| Q-2 | Offline sync within 10 s | 2 | NOT TESTED |
| Q-3 | 1,000 users and 50,000 tasks per organisation | 6 | NOT TESTED |
| Q-4 | App download under 25 MB | 0-7 | NOT TESTED (first CI APK size will be recorded) |
| Q-5 | Android 8.0+, 2 GB RAM | 7 | NOT TESTED (minSdk set in Sprint 1) |
| Q-6 | SUS 70+ | 7 | NOT TESTED |
| Q-7 | Daily backup kept 30 days | 7 | NOT TESTED |
| Q-8 | Every screen in Kiswahili and English, reviewed | 6 | NOT TESTED (ARB parity test exists) |
