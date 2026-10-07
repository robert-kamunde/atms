# ATMS Product Development Document

Oct 6, 2026 · @Robert Kamunde

## 1. Product overview

ATMS is a mobile app that moves an organisation's tasks through set approval steps, chases late work automatically, and keeps working without internet. Version 1 (the MVP) can be built by one or two developers in 16 weeks on Flutter and Firebase. This document specifies every module, says how each one works, and judges whether it will work.

**Who it is for.** Organisations of 10 to 1,000 staff in Tanzania (government offices, SACCOs, schools, NGOs, private companies) that today run tasks through WhatsApp, email, paper memos and phone calls.

**The problem in one line.** Nobody can see where a task is stuck, who is holding it, or why it is late, and multi-step approvals stall on one person's desk.

**What V1 must do**

1. Let a manager create a task, assign it, and set a deadline in under 30 seconds.
2. Route multi-step tasks (for example Officer, then Head of Department, then Director) automatically from one person to the next.
3. Remind people before deadlines and escalate overdue tasks to their supervisor without anyone chasing.
4. Keep confidential tasks (HR, Finance, Legal) visible only to the people who must see them.
5. Work on a cheap Android phone with poor or no internet, in Swahili or English.
6. Show managers where work is stuck, and produce weekly and monthly reports.

**Release plan**

| Release | What it includes | When |
| --- | --- | --- |
| V1 (MVP) | Modules 1 to 11 in section 4 | Weeks 1 to 16 |
| V1.1 | Web dashboard for managers, CSV/Excel import of staff, WhatsApp notifications | After the pilot |
| V2 | Parallel workflow steps, Gantt charts, recurring tasks, integrations (email, calendar, HR systems), USSD access | Later |

**Not in V1:** web app, Gantt charts, parallel or branching workflow steps, recurring tasks, time tracking, integrations, payments.

## 2. Users, roles and permissions

There are three base roles plus one extra permission, and every user also has a department and a supervisor. The supervisor link (the reporting line) is what escalation follows.

| Role | Who | Main jobs in the app |
| --- | --- | --- |
| Admin | IT officer or office manager (1 to 3 per organisation) | Sets up departments, users, reporting lines, workflow templates and settings; sees the audit log |
| Manager | Heads of department, supervisors, directors | Creates and assigns tasks, approves or rejects workflow steps, receives escalations, sees team dashboards and reports |
| Staff | Everyone else | Sees own tasks, updates status, comments, attaches files, submits work for review |
| + Confidential access (permission, not a role) | Named people in HR, Finance, Legal | Can see confidential tasks of their own department |

**Permission matrix**

| Action | Staff | Manager | Admin |
| --- | --- | --- | --- |
| View own tasks | Yes | Yes | Yes |
| View team's tasks | No | Own department and reports below them | All (except confidential) |
| View confidential tasks | Only if a participant | Only if a participant or has confidential access | Only with confidential access |
| Create a task | Only for themselves | For own team | Anyone |
| Start a workflow | If template allows | Yes | Yes |
| Approve or reject a step | Only if the step is assigned to them | Yes, when the step is theirs | No (unless the step is theirs) |
| Reassign a task | No | Within own team | Anyone |
| Delete a task | No | Own tasks, before work starts | Yes (soft delete, logged) |
| Manage users, departments, templates | No | No | Yes |
| View audit log | Own tasks only | Team's tasks | All |
| Download reports | Own | Team | Organisation |

Admins cannot see confidential content by default. This is deliberate: an IT administrator should not be able to read a disciplinary case.

## 3. System architecture

ATMS has no servers of its own to run: the phone app talks to Google's Firebase services, and Cloud Functions (highlighted) hold all the logic that must not be trusted to a phone.

&#91;embedded content: System architecture · phone, Firebase, SMS\]

The phone reads and writes tasks through Firestore, which keeps a copy on the phone for offline use. Approvals are sent as requests; a Cloud Function checks and applies them, then sends push notifications, and SMS through a Tanzanian provider for urgent events.

| Part | Technology | Why this choice |
| --- | --- | --- |
| Mobile app | Flutter (Dart), Riverpod for state, go\_router for screens | One codebase for Android and iOS; fast on low-end phones |
| Sign-in | Firebase Authentication (phone code, email fallback) | Phone sign-in fits users without email |
| Database | Cloud Firestore with offline persistence | Real-time updates and offline cache built in |
| Server logic | Cloud Functions (TypeScript) + Cloud Scheduler | Workflow moves, reminders, escalation, counters, reports |
| Files | Cloud Storage for Firebase | Same security rules model as the database |
| Push | Firebase Cloud Messaging | Free push to Android and iOS |
| SMS | Africa's Talking or Beem bulk-SMS API | Local delivery, pay per message |
| Languages | Flutter's built-in localisation (ARB files) | Kiswahili and English from one translation file each |
| Analytics and crashes | Firebase Analytics and Crashlytics | Adoption numbers for the pilot, crash reports |

## 4. Module specifications

V1 has 11 modules. Each one below lists what it does, how it works step by step, its screens, its rules, and the checks that prove it is done (acceptance criteria).

### 4.1 Sign-in and onboarding

**Purpose:** get a staff member from invitation to their first task in under 2 minutes.

**How it works**

1. The Admin adds a user with name, phone number, department, role and supervisor (or imports a list, V1.1).
2. The user receives an SMS: "You have been added to \[Organisation\] on ATMS. Download the app: \[link\]".
3. The user opens the app, enters their phone number, and receives a 6-digit one-time code by SMS (Firebase Phone Authentication).
4. On first sign-in the user picks a language (Kiswahili or English) and allows notifications.
5. The app downloads that user's tasks and stores them on the phone for offline use.

**Rules**

- Only phone numbers the Admin has added can sign in. An unknown number sees "Ask your administrator to add you."
- Email and password is offered as a fallback for staff without a reliable SIM.
- A session stays signed in for 30 days so staff are not asked for codes every day; Admins must sign in again every 7 days.
- When a user leaves, the Admin deactivates them; their open tasks go to their supervisor to reassign.

**Screens:** Phone entry, Code entry, Language choice, Notification permission.

**Done when**

- [ ] A new user can sign in with phone and code and see their tasks.
- [ ] An uninvited number cannot get in.
- [ ] A deactivated user is signed out within 1 hour and their tasks are flagged for reassignment.

### 4.2 Organisation setup

**Purpose:** model the organisation so the app knows who reports to whom.

**How it works**

1. The Admin creates departments (for example Finance, HR, ICT, Operations) and names a head for each.
2. The Admin adds users and sets each one's supervisor. This creates the reporting tree: Staff, then their supervisor, then the supervisor's supervisor, up to the top.
3. The Admin sets organisation-wide settings: working days, working hours, reminder times, escalation delay (default 24 hours) and the time zone (East Africa Time).

**Rules**

- Every user except the top person must have a supervisor. The app blocks loops (A reports to B who reports to A).
- Deadlines and escalation count working hours only if the organisation turns that on; otherwise they count calendar hours.

**Screens:** Departments list, User list and user editor, Reporting tree view, Settings.

**Done when**

- [ ] An Admin can set up a 50-person organisation with 5 departments in under 1 hour.
- [ ] The reporting tree shows correctly and loops are rejected.

### 4.3 Task management

**Purpose:** the core of the app: create, assign, track and finish tasks.

**A task has:** title, description, priority (Low, Medium, High, Urgent), deadline (date and time), assignee(s), creator, department, status, attachments, comments, a confidential flag, and an optional workflow template.

**Task statuses (simple task, no workflow)**

| Status | Meaning | Who moves it here |
| --- | --- | --- |
| To do | Assigned, not started | Creator, on creation |
| In progress | Assignee has started | Assignee |
| Blocked | Cannot continue; a reason is required | Assignee |
| Done | Finished | Assignee (or creator, if the creator requires a check) |
| Cancelled | No longer needed; a reason is required | Creator or Manager |

**How it works**

1. A Manager taps +, enters title, deadline, priority and assignee, and taps Save. Description and attachments are optional.
2. The assignee gets a notification and sees the task at the top of My Tasks, sorted by deadline.
3. The assignee moves the task through statuses with one tap each; Blocked and Cancelled ask for a reason.
4. A task assigned to several people is done only when all of them mark it done, unless the creator chose "any one person".
5. The creator can change the deadline; every change is logged and the assignee is notified.

**Screens:** My Tasks (list), Team Tasks (Managers), Kanban board (columns by status), Task detail, Create/edit task.

**Done when**

- [ ] A task can be created in under 30 seconds with only the required fields.
- [ ] Status changes show for the creator within 5 seconds when both are online.
- [ ] Filters work by status, priority, assignee, department and due date.

### 4.4 Workflow engine

**Purpose:** move a task through a fixed series of people automatically, so approvals no longer depend on someone remembering to pass the file on. This is the feature that sets ATMS apart.

**Workflow template.** An Admin defines a template once, for example "Purchase request":

| Step | Name | Done by | Needs approval | Time limit |
| --- | --- | --- | --- | --- |
| 1 | Prepare request | The person who starts it | No | 2 days |
| 2 | Department review | Requester's supervisor | Yes | 1 day |
| 3 | Finance check | Role: Finance Officer | Yes | 2 days |
| 4 | Final approval | Role: Director | Yes | 1 day |
| 5 | Procure | Role: Procurement Officer | No | 5 days |

A step can be done by a named person, by a role (for example Finance Officer), or by "the previous person's supervisor". The template's total time sets the overall deadline.

&#91;embedded content: Workflow step lifecycle · approve, reject, escalate\]

Every arrow in this picture is applied by a server function after it checks the request; the phone only asks.

**How it works**

1. A user starts a workflow by picking a template and filling in the request. Step 1 is assigned to them.
2. When the person on a step taps **Submit**, the app does not change the task itself. It sends a request to the server: "move task 123 from step 1 to step 2".
3. A server function checks the request: is this person the owner of the current step? Is the task still on that step? Are required fields and attachments present?
4. If the check passes, the server moves the task to the next step, works out who owns it (person, role or supervisor), sets that step's deadline, writes the audit log and sends notifications. If it fails, nothing changes and the user sees why.
5. On an approval step, the owner can **Approve** (go forward), **Reject** (back to the previous step, comment required) or **Send back** to any earlier step (comment required).
6. After the last step the task is **Completed** and the starter is notified.

**Why the server does the moving.** If phones changed the step themselves, two people approving offline at the same moment, or an old version of the app, could put a task in an impossible state. With one server function as the only thing allowed to move tasks, the workflow is always correct.

**Rules**

- Steps run one after another in V1. Parallel steps (two people at once) are V2.
- If a role has several people (three Finance Officers), the step goes to the one with the fewest open tasks, and any of them can pick it up.
- An Admin can edit a template; tasks already running keep the version they started with.
- A workflow can be cancelled by its starter or an Admin, with a reason.

**Screens:** Template list and template builder (Admin), Start workflow, Task detail with a step tracker (shows done, current and upcoming steps with names and dates), Approvals waiting (Managers).

**Done when**

- [ ] A 5-step template can be built in the app without code.
- [ ] Submitting a step assigns the next owner and notifies them within 10 seconds.
- [ ] Reject and send back return the task to the right step with the comment visible.
- [ ] Two approvals of the same step sent at the same time result in exactly one move.

### 4.5 Reminders and escalation

**Purpose:** chase late work automatically so managers do not have to.

**How it works.** A scheduled server job runs every 15 minutes and checks every open task (or workflow step) against its deadline:

| When | What happens | Who is told |
| --- | --- | --- |
| 24 hours before the deadline | Reminder | Assignee |
| 1 hour before the deadline | Final reminder | Assignee |
| Deadline passes | Task marked **Overdue** (red) | Assignee and creator |
| 24 hours overdue | **Escalation level 1** | Assignee's supervisor |
| 48 hours overdue | **Escalation level 2** | The supervisor's supervisor |
| 72 hours overdue | Escalation stops climbing; daily reminder continues | Level 2 person and the Admin's report |

**What the supervisor can do with an escalation:** extend the deadline (with a reason), reassign the task, or comment to the assignee. Each choice is logged.

**Rules**

- Times are configurable per organisation; the table shows the defaults.
- A task marked **Blocked** does not escalate, but its supervisor sees it in a Blocked list.
- Each reminder and escalation is sent once; the job records what it has sent so it never sends twice.
- If working hours are on, reminders that fall at night or at weekends are held until 08:00 on the next working day.

**Done when**

- [ ] Reminders arrive within 15 minutes of the due time.
- [ ] A task 24 hours overdue reaches the supervisor; at 48 hours, the next level.
- [ ] No reminder is ever sent twice for the same task and time.

### 4.6 Notifications

**Purpose:** tell people what needs them, cheaply and reliably.

**Channels, in order of use**

1. **In-app list** (bell icon): every notification, always. Free.
2. **Push notification** through Firebase Cloud Messaging. Free; arrives when the phone has data.
3. **SMS** through a Tanzanian bulk-SMS provider (for example Africa's Talking or Beem). Costs money per message, so it is used only for important events, and only when push is not opened within 30 minutes.

| Event | In-app | Push | SMS |
| --- | --- | --- | --- |
| Task assigned to you | Yes | Yes | Urgent priority only |
| Comment or @mention | Yes | Yes | No |
| Reminder 24 hours before | Yes | Yes | No |
| Reminder 1 hour before | Yes | Yes | If push not opened |
| Approval waiting for you | Yes | Yes | If push not opened |
| Escalation to you | Yes | Yes | Yes |
| Sign-in code | No | No | Yes |

**Rules**

- SMS text is short, in the user's language, and never contains confidential details: "ATMS: A task is overdue and needs your action. Open the app."
- Users can mute comment notifications but cannot mute escalations or approvals.
- The Admin sees SMS spend per month and can set a monthly cap.

**Done when**

- [ ] Every event in the table reaches the right channels.
- [ ] SMS is not sent when the push was opened in time.
- [ ] No SMS ever contains a confidential task's title.

### 4.7 Collaboration

**Purpose:** keep every conversation about a task on the task, instead of in WhatsApp.

**Features**

- **Comments** on each task, newest at the bottom, with the author and time.
- **@mentions**: typing @ lists people who can see the task; the person mentioned is notified.
- **Attachments**: photos (compressed on the phone to about 300 KB before upload), PDFs and Office files up to 10 MB.
- **Activity feed** inside each task: status changes, step moves and deadline changes appear between comments, so the history reads as one story.

**Rules**

- You can only @mention someone who can already see the task; mentioning does not grant access to a confidential task.
- Comments can be edited for 15 minutes, then they are locked. Deletions leave "comment removed" and are logged.
- On mobile data, attachments are not downloaded until the user taps them.
- Comments work offline; attachments wait in a queue until there is a connection.

**Done when**

- [ ] A comment typed offline appears for others after reconnection.
- [ ] A 4 MB phone photo uploads at under 500 KB.

### 4.8 Confidentiality and access control

**Purpose:** make sure people see only the tasks they are allowed to, enforced by the server, not just hidden in the app.

**How it works**

1. When creating a task, a user with confidential access ticks **Confidential**. They pick the participants (assignees and any reviewers).
2. The task stores a list of participant IDs and its department.
3. Firebase **Security Rules** on the server check every single read: the reader must be a participant, or hold confidential access for that department. Anyone else gets "not found", as if the task does not exist.
4. The same rule protects the task's comments and attachments (Cloud Storage rules).
5. Confidential tasks never appear in team lists, search, dashboards counts by name, notification text or SMS. Reports show them only as a count ("3 confidential tasks").

**Normal (non-confidential) visibility**

- Staff see tasks assigned to them or created by them.
- Managers also see tasks of everyone who reports to them, directly or further down.
- Admins see all non-confidential tasks.

**Done when**

- [ ] A user who is not a participant cannot read a confidential task even with a modified app (tested with the Firebase Emulator).
- [ ] Confidential titles never appear in push or SMS text.

### 4.9 Offline use and sync

**Purpose:** let people keep working with no internet, and never lose their work.

**What works offline**

| Action | Offline? |
| --- | --- |
| See my tasks and their details | Yes |
| Change status of a simple task | Yes |
| Write comments | Yes |
| Submit, approve or reject a workflow step | Queued: saved on the phone, checked by the server when online |
| Create a new task | Yes (assigned when online) |
| Upload attachments | Queued |
| Receive reminders and escalations | No (they arrive on reconnection; SMS still reaches the phone) |

**How it works**

1. Firebase Firestore keeps a copy of the user's data on the phone (offline persistence) and records every change made while offline.
2. A banner shows the state: "Offline: changes saved on this phone", then "Syncing...", then "All changes saved".
3. On reconnection, Firestore sends the queued changes in order.
4. Each change updates only the fields that were edited, so two people editing different fields (one the description, another the priority) do not overwrite each other.
5. Workflow moves are requests checked by the server (see 4.4). If a step was already approved by someone else, the late request is rejected and the user sees: "This step was already approved by Asha at 10:42."
6. If two people edit the same field offline, the later sync wins, and the audit log keeps both values so nothing is lost silently.

**Done when**

- [ ] A user can work for a full day offline and sync with no lost changes.
- [ ] Changes sync within 10 seconds of the connection returning.
- [ ] Conflicting workflow approvals produce one move and a clear message for the other user.

### 4.10 Dashboards and reports

**Purpose:** show managers where work is stuck at a glance, and give leadership numbers for performance reviews.

**Dashboards**

| Who | What they see |
| --- | --- |
| Staff | My tasks due today and this week, my overdue tasks, my completion rate this month |
| Manager | Team totals by status, overdue and escalated tasks highlighted, approvals waiting for me, workload per person, average days per workflow step (shows the bottleneck step) |
| Admin | Organisation totals by department, SMS spend, active users, templates in use |

**Reports**

- Weekly summary every Monday at 07:00, monthly summary on the 1st, sent as an in-app PDF and optionally by email.
- Contents: tasks created, completed, completed on time (%), overdue, escalated; average time per workflow step; top 5 longest-waiting tasks.
- Export to CSV for Excel.

**How it works.** Firestore is slow at counting large numbers of records, so a server function updates small counter documents (per user, per department, per day) every time a task changes. Dashboards read only those counters, which keeps them fast and cheap.

**Done when**

- [ ] Dashboards load in under 2 seconds on 3G.
- [ ] Report numbers match a manual count of the same tasks.

### 4.11 Audit log

**Purpose:** provide a permanent record of who did what and when, for accountability and disputes.

**What is logged:** task created, assigned, reassigned, status changed, deadline changed, step submitted, approved, rejected, sent back, escalated, comment edited or removed, task cancelled or deleted, user added or deactivated, template changed.

**Each entry holds:** who, what action, which task, old value, new value, time (server clock), and whether it was made offline.

**Rules**

- Only server functions write the log; no user, including Admins, can edit or delete it.
- Logs are kept for at least 3 years (configurable) to support audits.

**Done when**

- [ ] Every action in the list creates exactly one entry.
- [ ] An attempt to edit a log entry from the app is refused by the server.

## 5. Data model

All data lives in Cloud Firestore, grouped under each organisation so one installation can serve many organisations without their data mixing. Files live in Cloud Storage under the same organisation path.

| Collection (path) | Key fields | Written by |
| --- | --- | --- |
| orgs/{org} | name, timezone, workingHours, reminderHours \[24, 1\], escalationHours 24, smsMonthlyCap | Admin |
| orgs/{org}/departments/{dept} | name, headUserId | Admin |
| orgs/{org}/users/{user} | name, phone, email, role (admin, manager, staff), deptId, supervisorId, managerChain \[ids up the tree\], confidentialDepts \[ids\], language, fcmTokens, active | Admin; user edits own language |
| orgs/{org}/templates/{tpl} | name, version, steps \[{name, ownerType (user, role, supervisor), ownerRef, needsApproval, hoursAllowed}\], active | Admin |
| orgs/{org}/tasks/{task} | title, description, priority, status, deadline, creatorId, assigneeIds, deptId, confidential, participantIds, viewerIds, templateId, templateVersion, currentStep, stepDeadline, escalationLevel, overdue, createdAt, updatedAt | Users for simple fields; server for status of workflow tasks, currentStep, escalation |
| .../tasks/{task}/comments/{c} | authorId, text, mentions, editedAt, removed | Users |
| .../tasks/{task}/attachments/{a} | fileName, storagePath, sizeBytes, uploadedBy | Users |
| orgs/{org}/transitionRequests/{r} | taskId, fromStep, action (submit, approve, reject, sendBack), toStep, comment, requestedBy, result | User creates; server processes and fills result |
| orgs/{org}/notifications/{n} | userId, type, taskId, text, read, pushSent, smsSent | Server |
| orgs/{org}/audit/{entry} | taskId, actorId, action, before, after, at, madeOffline | Server only |
| orgs/{org}/stats/{scope\_day} | scope (user, dept, org), date, created, completed, onTime, overdue, escalated | Server only |

**Two design choices that make the rules simple and fast**

- **managerChain** on each user lists everyone above them. Visibility for managers is then one check: "is the manager's ID in the assignee's chain?"
- **viewerIds** on each task is filled by the server with every user allowed to see it (assignees, creator, their manager chains, or for confidential tasks only the participants). Lists then use one query: "tasks where viewerIds contains me", which Firestore indexes efficiently and which Security Rules can enforce.

**Indexes needed:** tasks by viewerIds + status + deadline; tasks by deptId + status; tasks by overdue + escalationLevel (for the escalation job).

## 6. Security and quality requirements

**Security**

- Every read and write is checked by Firestore and Storage Security Rules on Google's servers. The app is never trusted.
- Users can write only the simple fields of tasks they may edit. Fields that drive the workflow (status of workflow tasks, currentStep, escalationLevel, viewerIds) and the audit log are writable only by server functions.
- Data is encrypted in transit (HTTPS/TLS) and at rest (Google Cloud default). End-to-end encryption is not used, because the server must read tasks to route and remind.
- Admin accounts must use a second factor (email code) in addition to the phone code.
- Firebase App Check blocks requests that do not come from the genuine app.
- The privacy policy and consent screen follow the Tanzania Personal Data Protection Act, 2022. Only data needed to run tasks is collected.

**Quality targets**

| Area | Target | How it is checked |
| --- | --- | --- |
| Speed | Main screens open in under 2 s on a mid-range Android phone on 3G | Timed test on a real phone with network throttled |
| Sync | Offline changes saved to the server within 10 s of reconnecting | Scripted test |
| Scale | 1,000 users and 50,000 tasks per organisation without slowdown | Load test against the Firebase Emulator and a staging project |
| App size | Under 25 MB download | Build output |
| Phones | Android 8.0 and newer, 2 GB RAM | Test on one low-end phone |
| Usability | System Usability Scale score of 70 or more in the pilot | SUS questionnaire |
| Availability | Inherits Google's published Firestore service level; no servers of our own to keep up | Firebase status page |
| Backup | Daily automatic export of Firestore, kept 30 days | Scheduled export job |
| Languages | Every screen and message in Kiswahili and English | Translation file review by a native speaker |

## 7. Delivery plan

V1 takes 16 weeks in eight two-week sprints, built by one or two developers. Each sprint ends with a working build installed on test phones and shown to the supervisor or pilot organisation.

| Sprint | Weeks | Builds | Demo at the end |
| --- | --- | --- | --- |
| 0 | 1 to 2 | Interviews and baseline survey, final data model, wireframes, Firebase project, app skeleton, CI build | Clickable prototype (the demo in section 10) reviewed with 3 to 5 future users |
| 1 | 3 to 4 | 4.1 Sign-in, 4.2 Organisation setup, language switch | Admin sets up an organisation; staff sign in by phone |
| 2 | 5 to 6 | 4.3 Tasks, 4.9 Offline, 4.11 Audit log | Create, assign and finish tasks with Wi-Fi turned off |
| 3 | 7 to 8 | 4.4 Workflow engine | A 5-step purchase request runs end to end, with reject and send back |
| 4 | 9 to 10 | 4.5 Reminders and escalation, 4.6 Notifications (push, then SMS) | An overdue task escalates to the supervisor by push and SMS |
| 5 | 11 to 12 | 4.7 Collaboration, 4.8 Confidentiality | Comments, mentions, files; a confidential task invisible to others |
| 6 | 13 to 14 | 4.10 Dashboards and reports, Swahili translation, security rule tests, load test | Manager dashboard and weekly PDF |
| 7 | 15 to 16 | Pilot, fixes, user guide, final report | Pilot results against the targets in section 9 |

**If the schedule slips, cut in this order:** monthly report (keep weekly), Kanban board (keep list), SMS reminders (keep SMS sign-in and escalation), iOS build.

**Team**

| Role | Effort | Notes |
| --- | --- | --- |
| Flutter developer | Full time, 16 weeks | Can be the same person as below for a student project |
| Firebase / back-end developer | Half to full time | Cloud Functions, rules, scheduled jobs |
| Designer / tester | Part time | Wireframes in Sprint 0, testing from Sprint 2 |
| Swahili reviewer | A few days in Sprint 6 | Native speaker checks every string |
| Pilot contact | A few hours a week in Sprint 7 | Inside the pilot organisation |

**Running costs for a 50-user pilot (estimates to confirm)**

| Item | Cost |
| --- | --- |
| Google Play developer account | USD 25 once |
| Apple developer account (only for iOS) | USD 99 per year |
| Firebase Blaze plan (needed for scheduled functions) | Likely within the free daily allowances at pilot size; set a budget alert at USD 10 per month |
| SMS | Number of messages × the provider's quoted rate per SMS; sign-in codes plus escalations for 50 users should be a few hundred messages a month |
| Test phone (low-end Android) | One device |

## 8. Feasibility assessment

**Verdict: it will work technically, and V1 is achievable in 16 weeks by one strong developer or two average ones.** Every module uses standard, well-documented Firebase and Flutter features; nothing needs research. The real risks are adoption and scope, not technology.

**Module by module**

| Module | Difficulty | Main risk | Will it work? |
| --- | --- | --- | --- |
| 4.1 Sign-in | Low | SMS code delivery delays on some networks | Yes. Firebase Phone Auth works in Tanzania; email fallback covers gaps |
| 4.2 Organisation setup | Low | Admins entering 200 users by hand | Yes. Add CSV import in V1.1 |
| 4.3 Tasks | Low | None significant | Yes |
| 4.4 Workflow engine | **High** | Edge cases: reassignment mid-step, role with no members, template edited while running | Yes, if kept to sequential steps and all moves go through one server function. Most of the testing effort goes here |
| 4.5 Reminders and escalation | Medium | Sending twice, or missing one, when the job runs every 15 minutes | Yes, by recording each sent reminder on the task |
| 4.6 Notifications | Medium | Push is unreliable on some Android brands that kill background apps; SMS cost | Yes, with SMS as the fallback for important events and a monthly cap |
| 4.7 Collaboration | Low | Large photo uploads on slow data | Yes, with compression and queued uploads |
| 4.8 Confidentiality | Medium | A mistake in Security Rules leaks data | Yes, if rules are covered by automated tests in the Firebase Emulator |
| 4.9 Offline sync | **High** | Conflicting edits; users trusting a stale screen | Yes. Firestore's offline cache handles the storage; the design in 4.9 handles conflicts. Must be tested on real phones with flight mode |
| 4.10 Dashboards and reports | Medium | Slow, costly counting in Firestore | Yes, with pre-computed counters |
| 4.11 Audit log | Low | Log growing large | Yes. Firestore handles millions of small records cheaply |

**Biggest risks to the project as a whole**

1. **Adoption.** Staff already use WhatsApp, and it is free and familiar. If managers keep assigning work by WhatsApp, ATMS fails however good it is. Mitigation: a manager who commits to using it for one real process (for example leave requests or purchase requests) in the pilot, plus a WhatsApp-style simple interface.
2. **Scope creep.** Gantt charts, web app, integrations and analytics are each several weeks. Mitigation: the "Not in V1" list in section 1 is fixed until the pilot ends.
3. **Push notifications on cheap Android phones.** Some brands block background apps, so pushes arrive late. Mitigation: SMS fallback for escalations and approvals; an in-app guide to turn off battery restrictions.
4. **No pilot organisation.** Without real users there is no evaluation. Mitigation: get a signed letter of support in Sprint 0; fall back to a university department.
5. **Cost at scale.** At 50 users Firebase is close to free. At 1,000 active users reading lists all day, reads add up. Mitigation: paginate lists (20 tasks at a time), use the offline cache, and set budget alerts. SMS, not Firebase, is likely to be the largest running cost.

**Does it make sense as a product?** Yes, with a sharp focus. Trello, Asana, Jira, ClickUp and Microsoft Planner are strong general tools, so ATMS should not compete on features. Its case is a narrow one: approval-heavy organisations (government offices, SACCOs, schools, NGOs) that need routing and escalation along a reporting line, Swahili, SMS and offline use at a low price. Start with one process those organisations already run on paper, such as leave or purchase requests, and prove it there.

## 9. Testing and pilot

**Testing during development**

| Type | What | Tool |
| --- | --- | --- |
| Unit tests | Workflow step logic, escalation timing, permission checks | Dart test, Jest for Cloud Functions |
| Security rule tests | Every role trying to read and write every kind of task, including confidential | Firebase Emulator Suite |
| Widget tests | Main screens render and respond in both languages | Flutter widget tests |
| Offline tests | Work in flight mode, reconnect, check nothing is lost or duplicated | Manual script on a real low-end phone |
| Load test | 1,000 users, 50,000 tasks | Script against a staging Firebase project |
| Acceptance tests | Every "Done when" box in section 4 | Checklist, signed off each sprint |

**Pilot (weeks 15 to 16, longer if possible)**

- One organisation, 20 to 50 users, one or two real processes (for example purchase requests and leave requests).
- Before the pilot, measure the baseline: share of tasks finished late, and how many days a request waits for approval.

| Measure | Target |
| --- | --- |
| Tasks finished late | 30% fewer than baseline |
| Days a request waits for approval | 30% fewer than baseline |
| Usability (SUS) | 70 or more |
| Weekly active users | 70% of pilot users |
| Data lost during offline use | None |
| Reminders on time | 95% or more within 15 minutes |

Pilot users give informed consent; results are anonymised in the final report.

## 10. Demo prototype

The [ATMS prototype](https://claude.ai/artifact/6pFjAuVHr86V9rTdCP1cPL) is a clickable model of the app in a phone frame, with a "Behind the scenes" panel showing what the server, scheduler, push service and SMS gateway would do. It uses sample data only and is not the final app.

**Try these five things**

1. **Escalation:** as Asha (Finance Officer), open "Purchase 5 laptops". It is 26 hours overdue and already escalated to John. Press **+1 day** and watch it climb to Neema, with an SMS in the log.
2. **Workflow:** as Asha, approve the laptop request at "Finance check". Sign in as Neema, approve "Final approval", and see it move to Baraka for "Procure". Reject and Send back require a comment.
3. **Offline conflict:** press Reset demo data, then as Asha set the phone to **Offline** and approve the laptop request. Switch to John, reassign it to himself and approve it. Switch back to Asha and go **Online**: the server refuses her late approval and says who already approved it.
4. **Confidentiality:** the disciplinary task is visible to Rehema and Neema only. Sign in as Idrisa (Admin) or Asha and it does not exist for them. Push and SMS text never show its title.
5. **Roles and language:** compare the Dashboard for Asha (staff), Grace (manager) and Idrisa (admin), and switch the app to Kiswahili.

**What can be changed on request.** Everything the demo shows is driven by one settings block at the top of the page, so changes are quick:

| You can ask to change | Examples |
| --- | --- |
| Feature switches | Turn off SMS, remove the board view, hide confidential tasks (also switchable live in the demo controls) |
| Settings | Reminders at 48 h and 2 h; escalate after 12 h; climb 3 levels instead of 2 |
| People and reporting lines | Your real organisation's departments, job titles and who reports to whom |
| Workflow templates | Add a "Fuel request" or "Loan approval" template with your own steps and time limits |
| Sample tasks | Tasks that match your pilot organisation's real work |
| Wording and translation | Button labels, Swahili terms, organisation name |
| Screens | Add a screen (for example a calendar view) or change a layout |

The source file is saved in the project at atms-demo/atms-demo.html, so any later change keeps the same link.
