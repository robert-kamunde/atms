/**
 * Transaction reads shared by the assignment check, reassignTask and visibility upkeep: user
 * documents of the organisation, read in bounded groups.
 */
import type { Firestore, Transaction } from 'firebase-admin/firestore';
import { paths } from '../auth/deps';
import type { User } from '../shared/model';
import type { PersonFacts } from './assignment';

const GET_ALL_CHUNK = 100;

/** Reads the given users (missing users map to undefined). Reads only; safe before writes in a transaction. */
export async function readPeople(tx: Transaction, db: Firestore, org: string, uids: Iterable<string>): Promise<Map<string, PersonFacts | undefined>> {
  const ids = [...new Set(uids)];
  const out = new Map<string, PersonFacts | undefined>();
  for (let i = 0; i < ids.length; i += GET_ALL_CHUNK) {
    const part = ids.slice(i, i + GET_ALL_CHUNK);
    const snaps = await tx.getAll(...part.map((u) => db.doc(paths.user(org, u))));
    snaps.forEach((s, j) => {
      const u = s.data() as User | undefined;
      out.set(part[j], u ? { active: u.active === true, managerChain: Array.isArray(u.managerChain) ? u.managerChain : [] } : undefined);
    });
  }
  return out;
}

export function chainsOf(people: ReadonlyMap<string, PersonFacts | undefined>): Map<string, readonly string[]> {
  const out = new Map<string, readonly string[]>();
  for (const [uid, p] of people) if (p) out.set(uid, p.managerChain);
  return out;
}
