/**
 * ATMS Cloud Functions entry point.
 *
 * Functions arrive by sprint (docs/BACKLOG.md): Sprint 1 auth/ (adminUpsertUser,
 * deactivateUser, the admin second factor and the blocking sign-up and sign-in checks),
 * Sprint 2 tasks and audit/, Sprint 3 workflows/ (processTransitionRequest), Sprint 4
 * reminders/, escalation/ and notifications/, Sprint 6 counters/ and reports/.
 */
import { initializeApp } from 'firebase-admin/app';
import { setGlobalOptions } from 'firebase-functions/v2';
import { REGION } from './shared/config';

initializeApp();
setGlobalOptions({ region: REGION, maxInstances: 10 });

export {
  adminUpsertUserFn as adminUpsertUser,
  deactivateUserFn as deactivateUser,
  sendAdminCodeFn as sendAdminCode,
  verifyAdminCodeFn as verifyAdminCode,
  beforeUserCreatedFn as beforeUserCreated,
  beforeUserSignedInFn as beforeUserSignedIn,
} from './auth/functions';
