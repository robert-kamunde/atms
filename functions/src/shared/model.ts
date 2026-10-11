/**
 * Firestore data model shared by all Cloud Functions. Mirrors docs/ARCHITECTURE.md
 * ("Firestore schema"). Fields marked [deviation] are additions to PDD section 5,
 * each explained in docs/ARCHITECTURE.md ("Deviations from the PDD data model").
 */
import type { Timestamp } from 'firebase-admin/firestore';

export type Role = 'admin' | 'manager' | 'staff';
export type Language = 'en' | 'sw';
export type TaskStatus = 'todo' | 'in_progress' | 'blocked' | 'awaiting_check' | 'done' | 'cancelled';
/** Statuses an assignee is still working in. */
export const ACTIVE_STATUSES: readonly TaskStatus[] = ['todo', 'in_progress', 'blocked'];
/** Open = not final; awaiting_check (D-06) is open until the creator confirms or returns it. */
export const OPEN_STATUSES: readonly TaskStatus[] = [...ACTIVE_STATUSES, 'awaiting_check'];
export type Priority = 'low' | 'medium' | 'high' | 'urgent';
export type StepOwnerType = 'user' | 'role' | 'supervisor';
export type TransitionAction = 'submit' | 'approve' | 'reject' | 'sendBack';

export interface Org {
  name: string;
  timezone: string; // 'Africa/Dar_es_Salaam'
  workingHoursEnabled: boolean;
  workingHours: { start: string; end: string; days: number[] }; // days: 1 = Monday
  reminderHours: number[]; // default [24, 1]
  escalationHours: number; // default 24
  escalationMaxLevel: number; // default 2 [deviation: PDD fixes 2 levels; kept configurable per org]
  smsEnabled: boolean;
  smsMonthlyCap: number; // TZS
  auditRetentionYears: number; // >= 3
}

export interface Department {
  name: string;
  headUserId: string | null;
  active: boolean; // [deviation] departments are deactivated, never deleted
}

export interface User {
  name: string;
  role: Role;
  deptId: string;
  supervisorId: string | null;
  managerChain: string[]; // supervisor first, top of the tree last
  confidentialDepts: string[];
  /** Job title used by role-owned workflow steps, e.g. "Finance Officer". [deviation: PDD names roles in steps but has no field] */
  jobRole: string | null;
  language: Language;
  active: boolean;
  muteComments?: boolean;
  consentVersion?: string;
  consentAcceptedAt?: Timestamp;
}

/** users/{uid}/private/contact [deviation: phone and email moved out of the readable user doc] */
export interface UserContact {
  phone: string | null; // E.164, e.g. +2557...
  email: string | null;
}

export interface TemplateStep {
  name: string;
  ownerType: StepOwnerType;
  ownerRef: string | null; // uid for 'user', jobRole for 'role', null for 'supervisor'
  needsApproval: boolean;
  hoursAllowed: number;
}

export interface Template {
  name: string;
  version: number;
  steps: TemplateStep[];
  active: boolean;
  staffCanStart: boolean; // [deviation] "Start a workflow: Staff - if template allows"
}

export interface Task {
  title: string;
  description: string;
  priority: Priority;
  status: TaskStatus;
  deadline: Timestamp;
  creatorId: string;
  assigneeIds: string[];
  deptId: string;
  confidential: boolean;
  participantIds: string[];
  viewerIds: string[];
  templateId: string | null;
  templateVersion?: number;
  currentStep?: number; // 1-based
  stepDeadline?: Timestamp;
  escalationLevel: number;
  overdue: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  // [deviations]
  assignmentState: 'pending' | 'assigned' | 'rejected';
  assignmentError?: string;
  completionMode: 'all' | 'any';
  completedByIds: string[];
  /** D-06: the creator checks the work; an assignee's Done becomes awaiting_check. */
  needsCheck?: boolean;
  /** D-06: why the creator returned the task from awaiting_check to in_progress. */
  returnReason?: string;
  blockedReason?: string;
  cancelReason?: string;
  updatedBy: string;
  clientUpdatedAt?: Timestamp;
  deleted: boolean; // written as false on create so list queries can filter on it
  deletedAt?: Timestamp;
  remindersSent?: string[]; // idempotency keys, e.g. "due-24h", "esc-1"
  /** Server-only: set when an assignee is deactivated, cleared when the task is reassigned. */
  reassignmentNeeded?: boolean;
  reassignmentReason?: 'user_deactivated';
}

export interface TransitionRequest {
  taskId: string;
  fromStep: number;
  action: TransitionAction;
  toStep?: number;
  comment?: string;
  requestedBy: string;
  createdAt: Timestamp;
  clientCreatedAt?: Timestamp;
  result?: {
    status: 'applied' | 'rejected';
    code?: string; // see shared/errors.ts
    alreadyDoneBy?: string; // display name, for "already approved by Asha at 10:42"
    alreadyDoneAt?: Timestamp;
    processedAt: Timestamp;
  };
}

export interface AuditEntry {
  taskId: string | null;
  actorId: string; // uid or 'system'
  action: string;
  before: Record<string, unknown> | null;
  after: Record<string, unknown> | null;
  at: Timestamp;
  madeOffline: boolean;
  // [deviation] copied from the task so rules can enforce who reads the entry
  viewerIds: string[];
  confidential: boolean;
}

export type StatScope = 'user' | 'team' | 'dept' | 'org';
export interface Stat {
  scope: StatScope;
  scopeId: string; // [deviation]
  date: string; // YYYY-MM-DD in the org's time zone
  created: number;
  completed: number;
  onTime: number;
  overdue: number;
  escalated: number;
}
