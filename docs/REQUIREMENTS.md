# ATMS V1 requirements

Extracted from [PRODUCT_SPEC.md](PRODUCT_SPEC.md) (the PDD) and the client's master implementation
instructions (MI). Each requirement has an ID used by the backlog, the tests and the acceptance
checklist. Where the two sources differ, see [DECISIONS.md](DECISIONS.md).

Source key: `PDD 4.3` is a section of the product document; `MI 15` is a section of the master
instructions.

## 1. Functional requirements

### M1 Sign-in and onboarding (PDD 4.1, MI 8)

| ID | Requirement | Source |
| --- | --- | --- |
| AUTH-1 | An admin adds a user with name, phone, department, role and supervisor. | PDD 4.1.1 |
| AUTH-2 | The new user receives an invitation SMS: "You have been added to [Organisation] on ATMS. Download the app: [link]". | PDD 4.1.2 |
| AUTH-3 | Sign-in by phone number and a 6-digit one-time code (Firebase Phone Authentication). | PDD 4.1.3 |
| AUTH-4 | Email and password sign-in as a fallback for staff without a reliable SIM. | PDD 4.1 rules |
| AUTH-5 | Only numbers an admin has added can sign in; an unknown number sees "Ask your administrator to add you." | PDD 4.1 rules |
| AUTH-6 | On first sign-in the user picks Kiswahili or English and allows notifications. | PDD 4.1.4 |
| AUTH-7 | After sign-in the user's tasks download and are stored for offline use. | PDD 4.1.5 |
| AUTH-8 | Sessions last 30 days; admins sign in again every 7 days. | PDD 4.1 rules |
| AUTH-9 | Deactivating a user blocks access, signs them out within 1 hour and flags their open tasks for their supervisor to reassign. | PDD 4.1 rules, MI 8 |
| AUTH-10 | Admins need a second factor (email code) in addition to the phone code. | PDD 6, MI 29 |
| AUTH-11 | Privacy notice and consent screen following the Tanzania Personal Data Protection Act 2022. | PDD 6, MI 30 |

### M2 Organisation setup (PDD 4.2, MI 7)

| ID | Requirement | Source |
| --- | --- | --- |
| ORG-1 | Admin creates departments and names a head for each. | PDD 4.2.1 |
| ORG-2 | Admin adds users and sets each one's supervisor, building the reporting tree. | PDD 4.2.2 |
| ORG-3 | Every user belongs to a department; everyone except the top person has a supervisor. | PDD 4.2 rules, MI 7 |
| ORG-4 | Reporting loops are rejected. | PDD 4.2 rules |
| ORG-5 | managerChain (everyone above a user) is maintained for visibility checks. | PDD 5, MI 7 |
| ORG-6 | Organisation settings: working days, working hours, reminder times, escalation delay (default 24 h), time zone (East Africa Time). | PDD 4.2.3 |
| ORG-7 | If working hours are on, deadlines and escalation count working hours only; otherwise calendar hours. | PDD 4.2 rules |
| ORG-8 | Confidential access is a permission per department, not a role. | PDD 2, MI 7 |
| ORG-9 | Screens: departments list, user list and editor, reporting tree, settings. | PDD 4.2 |

### M3 Task management (PDD 4.3, MI 9)

| ID | Requirement | Source |
| --- | --- | --- |
| TASK-1 | A task has title, description, priority (Low, Medium, High, Urgent), deadline (date and time), assignees, creator, department, status, attachments, comments, a confidential flag and an optional workflow template. | PDD 4.3 |
| TASK-2 | Required fields: title, deadline, priority, assignee. Description and attachments optional. | PDD 4.3.1, MI 9 |
| TASK-3 | Statuses To do, In progress, Blocked, Done, Cancelled, with the movers in the PDD table. Blocked and Cancelled require a reason. | PDD 4.3, MI 9 |
| TASK-4 | Create permission: staff only for themselves, managers for their own team, admins for anyone. | PDD 2 matrix |
| TASK-5 | The assignee is notified and sees the task at the top of My Tasks, sorted by deadline. | PDD 4.3.2 |
| TASK-6 | Several assignees: Done only when all mark it done, unless the creator chose "any one person". | PDD 4.3.4, MI 9 |
| TASK-7 | The creator can change the deadline; each change is logged and the assignee notified. | PDD 4.3.5 |
| TASK-8 | Filters: status, priority, assignee, department, due date. | PDD 4.3, MI 9 |
| TASK-9 | Screens: My Tasks, Team Tasks (managers), Kanban board, task detail, create/edit. | PDD 4.3 |
| TASK-10 | Reassign: managers within their team, admins anyone. | PDD 2 matrix |
| TASK-11 | Delete: managers their own tasks before work starts; admins any (soft delete, logged). | PDD 2 matrix |
| TASK-12 | Visibility: staff see tasks assigned to or created by them; managers also their reporting tree; admins all non-confidential. | PDD 4.8, MI 9 |

### M4 Workflow engine (PDD 4.4, MI 10-14)

| ID | Requirement | Source |
| --- | --- | --- |
| WF-1 | Admins define templates of ordered steps: name, owner, needs approval, time limit. The template's total time sets the overall deadline. | PDD 4.4 |
| WF-2 | A step owner is a named user, a role, or "the previous person's supervisor". | PDD 4.4, MI 10 |
| WF-3 | Starting a workflow creates the task, assigns step 1 to the starter, sets the deadline, records the template version and notifies the owner. | PDD 4.4.1, MI 10 |
| WF-4 | Submit, approve, reject and send back are requests; a server function validates and applies them (the 14-step check in MI 4). If any check fails nothing changes and the user sees why. | PDD 4.4.2-4, MI 4 |
| WF-5 | Approve moves forward; Reject returns to the previous step; Send back returns to any earlier step. Reject and send back require a comment. | PDD 4.4.5, MI 12 |
| WF-6 | After the last step the task is Completed and the starter notified. | PDD 4.4.6 |
| WF-7 | Two approvals of the same step at the same time produce exactly one move; the other gets "This step was already approved by Asha at 10:42." | PDD 4.4, 4.9, MI 11 |
| WF-8 | Steps are strictly sequential (no parallel or branching steps). | PDD 4.4 rules |
| WF-9 | A role step goes to the eligible person with the fewest open tasks, and any eligible person can pick it up. If nobody is eligible, an admin error is raised; the workflow is never silently stuck. | PDD 4.4 rules, MI 14 |
| WF-10 | Editing a template never changes running tasks; they keep their version. | PDD 4.4 rules, MI 13 |
| WF-11 | The starter or an admin can cancel a workflow, with a reason. | PDD 4.4 rules |
| WF-12 | Staff may start a workflow only if the template allows it. | PDD 2 matrix |
| WF-13 | Approve or reject only when the step is assigned to you (admins included). | PDD 2 matrix |
| WF-14 | Screens: template list and builder (admin), start workflow, task detail with step tracker, approvals waiting. | PDD 4.4 |

### M5 Reminders and escalation (PDD 4.5, MI 15)

| ID | Requirement | Source |
| --- | --- | --- |
| REM-1 | A scheduled job runs every 15 minutes over open tasks and workflow steps. | PDD 4.5 |
| REM-2 | Reminder 24 h before, final reminder 1 h before, Overdue at the deadline (assignee and creator told). | PDD 4.5 table |
| REM-3 | Escalation level 1 at 24 h overdue to the supervisor; level 2 at 48 h to the supervisor's supervisor; at 72 h it stops climbing and a daily reminder continues to the level-2 person and the admin's report. | PDD 4.5 table, MI 15 |
| REM-4 | Times configurable per organisation. | PDD 4.5 rules |
| REM-5 | Blocked tasks do not escalate; supervisors see them in a Blocked list. | PDD 4.5 rules |
| REM-6 | Every reminder and escalation is sent once; the job records what it sent. | PDD 4.5 rules, MI 15 |
| REM-7 | With working hours on, reminders falling at night or weekends wait until 08:00 on the next working day. | PDD 4.5 rules |
| REM-8 | A supervisor can extend the deadline (with reason), reassign, or comment on an escalated task; each choice is logged. | PDD 4.5 |

### M6 Notifications (PDD 4.6, MI 16-17)

| ID | Requirement | Source |
| --- | --- | --- |
| NOT-1 | Channels in order: in-app list (always), push (FCM), SMS (important events only). | PDD 4.6 |
| NOT-2 | Event channel table: assigned (SMS if urgent), comment/mention (no SMS), 24 h reminder (no SMS), 1 h reminder and approval waiting (SMS if push not opened), escalation (always SMS), sign-in code (SMS only). | PDD 4.6 table |
| NOT-3 | SMS is sent only if the push is not opened within 30 minutes (escalations always eligible). | PDD 4.6, MI 17 |
| NOT-4 | SMS text is short, in the user's language and never contains confidential details. Push text, previews and logs never show confidential titles. | PDD 4.6, MI 16 |
| NOT-5 | Users can mute comment notifications but not escalations or approvals. | PDD 4.6 rules |
| NOT-6 | The admin sees SMS spend per month and sets a monthly cap, which is never exceeded. Sent, failed, cost and usage are tracked. | PDD 4.6, MI 17 |
| NOT-7 | SMS goes through a provider interface (Africa's Talking or Beem). | PDD 3, MI 3 |

### M7 Collaboration (PDD 4.7, MI 18)

| ID | Requirement | Source |
| --- | --- | --- |
| COL-1 | Comments with author and time, newest at the bottom. | PDD 4.7 |
| COL-2 | @mentions list only people who can see the task; mentioning never grants access; the mentioned person is notified. | PDD 4.7 |
| COL-3 | Attachments: photos compressed on the phone to about 300 KB, PDFs and Office files up to 10 MB. | PDD 4.7 |
| COL-4 | Activity feed: status changes, step moves and deadline changes appear between comments. | PDD 4.7 |
| COL-5 | Comments editable for 15 minutes, then locked. Deletion leaves "Comment removed" and is logged. | PDD 4.7 rules |
| COL-6 | On mobile data attachments download only when tapped. | PDD 4.7 rules |
| COL-7 | Comments work offline; attachments queue until there is a connection. | PDD 4.7 rules |

### M8 Confidentiality and access control (PDD 4.8, MI 19)

| ID | Requirement | Source |
| --- | --- | --- |
| CONF-1 | Users with confidential access can mark a task Confidential and pick its participants. | PDD 4.8.1 |
| CONF-2 | A confidential task can be read only by participants or by holders of confidential access for its department; anyone else gets "not found". Enforced by Security Rules. | PDD 4.8.3 |
| CONF-3 | The same rule protects comments and attachments (Storage rules). | PDD 4.8.4 |
| CONF-4 | Confidential tasks never appear in team lists, search, dashboard names, notification text or SMS; reports show counts only. | PDD 4.8.5, MI 19 |
| CONF-5 | Admins cannot see confidential content unless they hold confidential access. | PDD 2 |

### M9 Offline use and sync (PDD 4.9, MI 20-23)

| ID | Requirement | Source |
| --- | --- | --- |
| OFF-1 | Offline: view tasks and details, change simple status, write comments, create tasks (assigned when online). | PDD 4.9 table |
| OFF-2 | Workflow submit/approve/reject are queued as requests and checked by the server when online. | PDD 4.9 table, MI 21 |
| OFF-3 | Attachments upload from a queue. | PDD 4.9 table |
| OFF-4 | Banner: "Offline: changes saved on this phone", "Syncing...", "All changes saved". | PDD 4.9.2 |
| OFF-5 | Changes are field-level, so edits to different fields do not overwrite each other. | PDD 4.9.4, MI 22 |
| OFF-6 | Same field edited offline by two people: the later sync wins and the audit log keeps both values. | PDD 4.9.6, MI 22 |
| OFF-7 | A late workflow request is rejected with "This step was already approved by Asha at 10:42." | PDD 4.9.5, MI 21 |
| OFF-8 | Queued operations survive app restarts; no lost or duplicated changes. | MI 23 |

### M10 Dashboards and reports (PDD 4.10, MI 24-25)

| ID | Requirement | Source |
| --- | --- | --- |
| DASH-1 | Staff: my tasks due today and this week, my overdue tasks, my completion rate this month. | PDD 4.10 |
| DASH-2 | Manager: team totals by status, overdue and escalated highlighted, approvals waiting for me, workload per person, average days per workflow step (bottleneck). | PDD 4.10 |
| DASH-3 | Admin: organisation totals by department, SMS spend, active users, templates in use. | PDD 4.10 |
| DASH-4 | Dashboards read server-maintained counters only. | PDD 4.10, MI 24 |
| REP-1 | Weekly report every Monday at 07:00 and monthly on the 1st, as an in-app PDF and optionally by email. | PDD 4.10 |
| REP-2 | Contents: created, completed, completed on time (%), overdue, escalated, average time per workflow step, top 5 longest-waiting tasks. MI 25 adds completion rate. | PDD 4.10, MI 25 |
| REP-3 | CSV export for Excel. | PDD 4.10 |
| REP-4 | Download scope: staff own, manager team, admin organisation. Confidential tasks only as counts. | PDD 2, 4.8 |

### M11 Audit log (PDD 4.11, MI 26)

| ID | Requirement | Source |
| --- | --- | --- |
| AUD-1 | Logged actions: task created, assigned, reassigned, status changed, deadline changed, step submitted, approved, rejected, sent back, escalated, comment edited or removed, task cancelled or deleted, user added or deactivated, template changed. | PDD 4.11 |
| AUD-2 | Each entry: who, action, task, old value, new value, server time, made offline. | PDD 4.11 |
| AUD-3 | Only server functions write the log; nobody edits or deletes it. | PDD 4.11 |
| AUD-4 | Kept at least 3 years (configurable). | PDD 4.11 |
| AUD-5 | Read scope: staff own tasks, managers team tasks, admins all. | PDD 2 matrix |

## 2. Roles and permissions

Three roles (Admin, Manager, Staff) plus the per-department Confidential access permission. The
permission matrix in PDD section 2 is reproduced below with how each cell is enforced.

| Action | Staff | Manager | Admin | Enforced by |
| --- | --- | --- | --- | --- |
| View own tasks | Yes | Yes | Yes | Rules: uid in viewerIds |
| View team's tasks | No | Own department and reports below | All non-confidential | viewerIds (server adds managerChain); admin rule on confidential == false |
| View confidential tasks | If participant | If participant or confidential access | Only with confidential access | Rules: viewerIds (participants only) or deptId in confidentialDepts |
| Create a task | Only for themselves | For own team | Anyone | Server check on create ("assigned when online"); see DECISIONS A-01 |
| Start a workflow | If template allows | Yes | Yes | Server check (template.staffCanStart) |
| Approve or reject a step | If the step is theirs | When the step is theirs | Only if the step is theirs | Server transition processor |
| Reassign | No | Within own team | Anyone | Server callable |
| Delete | No | Own tasks before work starts | Yes (soft, logged) | Rules (soft delete fields) + audit trigger |
| Manage users, departments, templates | No | No | Yes | Server callables (users, templates); rules (departments, settings) with admin second factor |
| View audit log | Own tasks | Team's tasks | All | Rules: audit.viewerIds, admin rule |
| Download reports | Own | Team | Organisation | Server report generation and rules on reports |

"Own department and reports below" for managers is implemented as the reporting tree
(managerChain), as PDD 4.8 states ("everyone who reports to them, directly or further down").
See DECISIONS A-03 for the department part.

## 3. Security requirements

| ID | Requirement | Source |
| --- | --- | --- |
| SEC-1 | Every read and write is checked by Firestore and Storage Security Rules; the app is never trusted. | PDD 6, MI 4, 27 |
| SEC-2 | Workflow-driving fields (workflow status, currentStep, stepDeadline, escalationLevel, overdue, viewerIds) and the audit log are server-only. | PDD 6, MI 4 |
| SEC-3 | Organisation isolation; role permissions; department visibility; comment and attachment visibility; audit immutability. | MI 27 |
| SEC-4 | Encryption in transit (TLS) and at rest (Google default). No claim of end-to-end encryption. | PDD 6, MI 30 |
| SEC-5 | Admin second factor (email code). | PDD 6, MI 29 |
| SEC-6 | Firebase App Check. | PDD 6, MI 28 |
| SEC-7 | Privacy policy and consent per Tanzania PDPA 2022; collect only data needed. | PDD 6, MI 30 |
| SEC-8 | Confidential data never in notifications, SMS, previews or logs readable by unauthorised people. | MI 16 |
| SEC-9 | Emulator tests: every role against normal, confidential, other-department and other-user tasks, comments, attachments and audit logs, allowed and denied. Critical: a modified client cannot read a confidential task. | PDD 4.8, MI 36 |

## 4. Offline requirements

OFF-1 to OFF-8 above, plus: sync within 10 s of reconnection (PDD 6), a full-day offline test
(PDD 4.9), and tests for flight mode, create/status/comment/approval offline, reconnect, restart
while offline, duplicate sync and conflict resolution (MI 36).

## 5. Notification requirements

NOT-1 to NOT-7, REM-1 to REM-8 and COL-2 above. Server-generated only (MI 4). Idempotent: never
twice (MI 15).

## 6. Performance and quality targets (PDD 6, MI 33)

| ID | Target | How checked |
| --- | --- | --- |
| PERF-1 | Main screens open in under 2 s on a mid-range Android phone on 3G | Timed test, throttled network |
| PERF-2 | Offline changes synced within 10 s of reconnecting | Scripted test |
| PERF-3 | 1,000 users and 50,000 tasks per organisation without slowdown | Load test (emulator and staging) |
| PERF-4 | App download under 25 MB | Build output |
| PERF-5 | Android 8.0+, 2 GB RAM | Low-end test phone |
| PERF-6 | SUS 70+ in the pilot | Questionnaire |
| PERF-7 | Task created in under 30 s; new user to first task in under 2 min | Timed usability test |
| PERF-8 | Daily Firestore export kept 30 days | Scheduled export job |
| PERF-9 | Every screen and message in Kiswahili and English, reviewed by a native speaker | Translation review |
| PERF-10 | Lists paginated (20 per page); never load all tasks | Code review, tests |

## 7. Out of scope for V1 (MI 2)

Web app, Gantt charts, parallel or branching workflow steps, recurring tasks, time tracking,
external integrations, payments, USSD, WhatsApp notifications, CSV/Excel staff import.
