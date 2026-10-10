/** What the Sprint 2 task handlers need from the outside world (tests pass the emulator and a test clock). */
import type { Firestore } from 'firebase-admin/firestore';

export interface TaskDeps {
  db: Firestore;
  /** Current time in epoch milliseconds. */
  now: () => number;
}

/** Largest number of tasks read or written in one page (no unbounded queries). */
export const TASK_PAGE = 200;
