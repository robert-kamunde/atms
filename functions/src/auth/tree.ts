/**
 * Reporting tree logic (PDD 4.2): loop detection and managerChain computation. Pure functions,
 * so they are unit tested without Firestore; adminUpsertUser feeds them what it read in a
 * transaction.
 */
import { AtmsError, ErrorCode } from '../shared/errors';

export class ReportingLoopError extends AtmsError {
  constructor() {
    super('failed-precondition', ErrorCode.reportingLoop, 'This supervisor would create a reporting loop.');
  }
}

/**
 * Computes managerChain (supervisor first, top of the tree last) for every node in `nodes`.
 *
 * @param nodes uid -> supervisorId (null for the top person), after the change being made.
 * @param outside managerChain of supervisors that are not in `nodes`, as stored. Every node's
 *   walk upwards must end at a top person or at one of these.
 * @throws ReportingLoopError when following supervisors from a node returns to that node.
 */
export function computeChains(
  nodes: ReadonlyMap<string, string | null>,
  outside: ReadonlyMap<string, readonly string[]>,
): Map<string, string[]> {
  const done = new Map<string, string[]>();

  const chainOf = (start: string): string[] => {
    const cached = done.get(start);
    if (cached) return cached;
    // Walk up until a node whose chain is known, then fill in the chains on the way back.
    const path: string[] = [];
    const onPath = new Set<string>();
    let cur: string | null = start;
    let tail: string[] = [];
    while (cur !== null) {
      if (onPath.has(cur)) throw new ReportingLoopError();
      const known = done.get(cur);
      if (known) { tail = [cur, ...known]; break; }
      if (!nodes.has(cur)) {
        const ext = outside.get(cur);
        if (!ext) throw new AtmsError('internal', ErrorCode.internal, `Supervisor ${cur} was not loaded`);
        if (path.some((p) => ext.includes(p))) throw new ReportingLoopError();
        tail = [cur, ...ext];
        break;
      }
      path.push(cur);
      onPath.add(cur);
      cur = nodes.get(cur) ?? null;
    }
    // path[i]'s chain is path[i+1..] followed by tail.
    for (let i = path.length - 1; i >= 0; i--) {
      const chain = [...path.slice(i + 1), ...tail];
      if (chain.includes(path[i])) throw new ReportingLoopError();
      done.set(path[i], chain);
    }
    return done.get(start) as string[];
  };

  for (const uid of nodes.keys()) chainOf(uid);
  return done;
}

/** True when two chains are equal (used to write only the documents that change). */
export function sameChain(a: readonly string[] | undefined, b: readonly string[]): boolean {
  return !!a && a.length === b.length && a.every((v, i) => v === b[i]);
}

/** Splits a list into chunks of at most `size` (Firestore commits are kept well under 500 writes). */
export function chunk<T>(items: readonly T[], size: number): T[][] {
  if (size < 1) throw new Error('chunk size must be positive');
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
  return out;
}
