import { chunk, computeChains, ReportingLoopError, sameChain } from '../../src/auth/tree';
import { ErrorCode } from '../../src/shared/errors';

const m = (pairs: [string, string | null][]) => new Map(pairs);

describe('reporting tree (PDD 4.2)', () => {
  test('managerChain lists the supervisor first and the top person last', () => {
    const chains = computeChains(m([['neema', null], ['john', 'neema'], ['asha', 'john']]), new Map());
    expect(chains.get('neema')).toEqual([]);
    expect(chains.get('john')).toEqual(['neema']);
    expect(chains.get('asha')).toEqual(['john', 'neema']);
  });

  test('a supervisor outside the changed set contributes their stored chain', () => {
    const chains = computeChains(m([['asha', 'john'], ['baby', 'asha']]), new Map([['john', ['neema']]]));
    expect(chains.get('asha')).toEqual(['john', 'neema']);
    expect(chains.get('baby')).toEqual(['asha', 'john', 'neema']);
  });

  test('moving a manager recomputes everyone below them', () => {
    // John moves from Neema to Grace; Asha reports to John.
    const chains = computeChains(m([['john', 'grace'], ['asha', 'john']]), new Map([['grace', ['neema']]]));
    expect(chains.get('asha')).toEqual(['john', 'grace', 'neema']);
  });

  test('A reports to B who reports to A is rejected', () => {
    expect(() => computeChains(m([['a', 'b'], ['b', 'a']]), new Map())).toThrow(ReportingLoopError);
  });

  test('self-supervision and longer loops are rejected', () => {
    expect(() => computeChains(m([['a', 'a']]), new Map())).toThrow(ReportingLoopError);
    expect(() => computeChains(m([['a', 'b'], ['b', 'c'], ['c', 'a'], ['d', 'a']]), new Map())).toThrow(ReportingLoopError);
  });

  test('a loop through a stored chain outside the changed set is rejected', () => {
    // Asha's new supervisor is Baraka, whose stored chain already contains Asha.
    expect(() => computeChains(m([['asha', 'baraka']]), new Map([['baraka', ['asha', 'neema']]]))).toThrow(ReportingLoopError);
  });

  test('the loop error carries the reporting-loop code for the app', () => {
    try {
      computeChains(m([['a', 'b'], ['b', 'a']]), new Map());
      throw new Error('expected a loop');
    } catch (e) {
      expect((e as ReportingLoopError).code).toBe(ErrorCode.reportingLoop);
    }
  });

  test('a missing supervisor is an internal error, not a silent root', () => {
    expect(() => computeChains(m([['asha', 'ghost']]), new Map())).toThrow(/not loaded/);
  });

  test('a 1,000-person chain is computed without recursion limits', () => {
    const pairs: [string, string | null][] = [['u0', null]];
    for (let i = 1; i < 1000; i++) pairs.push([`u${i}`, `u${i - 1}`]);
    const chains = computeChains(m(pairs), new Map());
    expect(chains.get('u999')).toHaveLength(999);
    expect(chains.get('u999')?.[0]).toBe('u998');
  });

  test('sameChain and chunk helpers', () => {
    expect(sameChain(['a', 'b'], ['a', 'b'])).toBe(true);
    expect(sameChain(['a'], ['a', 'b'])).toBe(false);
    expect(sameChain(undefined, [])).toBe(false);
    expect(chunk([1, 2, 3, 4, 5], 2)).toEqual([[1, 2], [3, 4], [5]]);
    expect(chunk(Array.from({ length: 1000 }, (_, i) => i), 400).map((c) => c.length)).toEqual([400, 400, 200]);
  });
});
