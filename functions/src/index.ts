/**
 * ATMS Cloud Functions entry point.
 *
 * Sprint 0 sets up the project only. Functions arrive by sprint (docs/BACKLOG.md):
 * Sprint 1 auth/ (adminUpsertUser, blocking sign-in check, admin second factor), Sprint 2
 * tasks and audit/, Sprint 3 workflows/ (processTransitionRequest), Sprint 4 reminders/,
 * escalation/ and notifications/, Sprint 6 counters/ and reports/.
 */
import { initializeApp } from 'firebase-admin/app';
import { setGlobalOptions } from 'firebase-functions/v2';
import { REGION } from './shared/config';

initializeApp();
setGlobalOptions({ region: REGION, maxInstances: 10 });
