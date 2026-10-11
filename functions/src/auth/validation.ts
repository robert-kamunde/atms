/**
 * Input validation for the Sprint 1 callables (docs/SPRINT1_CONTRACT.md). The app is never
 * trusted: every field is checked for type, length and format, and unknown fields are refused.
 */
import { validationError } from '../shared/errors';
import type { Language, Role } from '../shared/model';

export interface UpsertUserInput {
  uid?: string;
  name: string;
  phone: string | null;
  email: string | null;
  role: Role;
  deptId: string;
  supervisorId: string | null;
  jobRole: string | null;
  language: Language;
  confidentialDepts: string[];
}

const UPSERT_KEYS = new Set([
  'uid', 'name', 'phone', 'email', 'role', 'deptId', 'supervisorId', 'jobRole', 'language', 'confidentialDepts',
]);
const ROLES: readonly Role[] = ['admin', 'manager', 'staff'];
const LANGUAGES: readonly Language[] = ['en', 'sw'];

/** Tanzanian numbers in E.164: +255 followed by 9 digits. */
export const TZ_PHONE = /^\+255\d{9}$/;
const EMAIL = /^[^\s@/\\"<>()]+@[^\s@/\\"<>()]+\.[^\s@/\\"<>()]+$/;
/** Firestore document ids we accept from the app: no slashes, no control characters. */
const DOC_ID = /^[A-Za-z0-9_-]{1,128}$/;

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

function docId(v: unknown, field: string): string {
  if (typeof v !== 'string' || !DOC_ID.test(v)) throw validationError(field, `${field} must be a valid id`);
  return v;
}

function text(v: unknown, field: string, max: number): string {
  if (typeof v !== 'string') throw validationError(field, `${field} must be text`);
  const t = v.trim();
  if (t.length === 0 || t.length > max) throw validationError(field, `${field} must be 1 to ${max} characters`);
  return t;
}

export function normalisePhone(v: unknown): string | null {
  if (v === null) return null;
  if (typeof v !== 'string' || !TZ_PHONE.test(v)) {
    throw validationError('phone', 'phone must be a Tanzanian number in the form +255XXXXXXXXX');
  }
  return v;
}

export function normaliseEmail(v: unknown): string | null {
  if (v === null) return null;
  if (typeof v !== 'string') throw validationError('email', 'email must be text');
  const e = v.trim().toLowerCase();
  if (e.length > 254 || !EMAIL.test(e)) throw validationError('email', 'email is not a valid address');
  return e;
}

export function validateUpsertInput(data: unknown): UpsertUserInput {
  if (!isRecord(data)) throw validationError('input', 'input must be an object');
  for (const k of Object.keys(data)) {
    if (!UPSERT_KEYS.has(k)) throw validationError(k, `unknown field ${k}`);
  }
  const uid = data.uid === undefined ? undefined : docId(data.uid, 'uid');
  const name = text(data.name, 'name', 100);
  if (!('phone' in data)) throw validationError('phone', 'phone is required (null if none)');
  if (!('email' in data)) throw validationError('email', 'email is required (null if none)');
  const phone = normalisePhone(data.phone);
  const email = normaliseEmail(data.email);
  if (phone === null && email === null) throw validationError('phone', 'a phone number or an email is required');
  if (!ROLES.includes(data.role as Role)) throw validationError('role', 'role must be admin, manager or staff');
  const deptId = docId(data.deptId, 'deptId');
  if (data.supervisorId !== null && data.supervisorId === undefined) {
    throw validationError('supervisorId', 'supervisorId is required (null for the top person)');
  }
  const supervisorId = data.supervisorId === null ? null : docId(data.supervisorId, 'supervisorId');
  if (uid !== undefined && supervisorId === uid) {
    throw validationError('supervisorId', 'a person cannot be their own supervisor');
  }
  if (data.jobRole !== null && data.jobRole === undefined) throw validationError('jobRole', 'jobRole is required (null if none)');
  const jobRole = data.jobRole === null ? null : text(data.jobRole, 'jobRole', 100);
  if (!LANGUAGES.includes(data.language as Language)) throw validationError('language', 'language must be en or sw');
  if (!Array.isArray(data.confidentialDepts) || data.confidentialDepts.length > 50) {
    throw validationError('confidentialDepts', 'confidentialDepts must be a list of at most 50 department ids');
  }
  const confidentialDepts = [...new Set(data.confidentialDepts.map((d) => docId(d, 'confidentialDepts')))];
  return {
    ...(uid !== undefined ? { uid } : {}),
    name, phone, email, role: data.role as Role, deptId, supervisorId, jobRole,
    language: data.language as Language, confidentialDepts,
  };
}

export function validateUidInput(data: unknown): { uid: string } {
  if (!isRecord(data)) throw validationError('input', 'input must be an object');
  for (const k of Object.keys(data)) if (k !== 'uid') throw validationError(k, `unknown field ${k}`);
  return { uid: docId(data.uid, 'uid') };
}

export function validateEmptyInput(data: unknown): void {
  if (data === null || data === undefined) return;
  if (!isRecord(data) || Object.keys(data).length > 0) throw validationError('input', 'no input expected');
}

export function validateCodeInput(data: unknown): { code: string } {
  if (!isRecord(data)) throw validationError('input', 'input must be an object');
  for (const k of Object.keys(data)) if (k !== 'code') throw validationError(k, `unknown field ${k}`);
  if (typeof data.code !== 'string' || !/^\d{6}$/.test(data.code)) throw validationError('code', 'the code has 6 digits');
  return { code: data.code };
}
