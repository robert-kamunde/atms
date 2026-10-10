/**
 * Everything the Sprint 1 handlers need from the outside world, passed in so the handlers can
 * be tested against the emulators with fakes for SMS, e-mail and the clock.
 */
import type { Auth } from 'firebase-admin/auth';
import type { Firestore } from 'firebase-admin/firestore';
import type { EmailProvider } from '../notifications/email/provider';
import type { SmsProvider } from '../notifications/sms/provider';

export interface Deps {
  db: Firestore;
  auth: Auth;
  /** Returns the SMS provider; throws when none is configured for this project. */
  sms: () => SmsProvider;
  /** Returns the e-mail provider; throws when none is configured for this project. */
  email: () => EmailProvider;
  /** Current time in epoch milliseconds. */
  now: () => number;
  appDownloadUrl: () => string;
  /** Writes per transaction before a tree update switches to locked, chunked writes (default 400). */
  maxTransactionWrites?: number;
}

/** The verified identity of a callable's caller (from request.auth). */
export interface CallerAuth {
  uid: string;
  token: Record<string, unknown>;
}

export const paths = {
  org: (org: string) => `orgs/${org}`,
  user: (org: string, uid: string) => `orgs/${org}/users/${uid}`,
  contact: (org: string, uid: string) => `orgs/${org}/users/${uid}/private/contact`,
  dept: (org: string, dept: string) => `orgs/${org}/departments/${dept}`,
  users: (org: string) => `orgs/${org}/users`,
  tasks: (org: string) => `orgs/${org}/tasks`,
  task: (org: string, taskId: string) => `orgs/${org}/tasks/${taskId}`,
  audit: (org: string) => `orgs/${org}/audit`,
  /**
   * Admin second-factor record read by triggers (which cannot see custom claims). The contract's
   * `secure/adminVerification/{uid}` is a collection path, so an extra `admins` segment is added.
   */
  adminVerification: (org: string, uid: string) => `orgs/${org}/secure/adminVerification/admins/${uid}`,
  /** One document per admin (the contract's `secure/adminCodes/{uid}` needs an extra segment). */
  adminCode: (org: string, uid: string) => `orgs/${org}/secure/adminCodes/codes/${uid}`,
  /** Lock held while a large reporting-tree update is written in chunks. */
  treeLock: (org: string) => `orgs/${org}/secure/reportingTree`,
};
