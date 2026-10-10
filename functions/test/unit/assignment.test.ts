import { adminVerifiedAt, checkAssignment, completionStatus, computeViewerIds, mayAssign, type Assigner, type PersonFacts } from '../../src/tasks/assignment';

const p = (managerChain: string[], active = true): PersonFacts => ({ active, managerChain });
const people = new Map<string, PersonFacts | undefined>([
  ['neema', p([])],
  ['john', p(['neema'])],
  ['asha', p(['john', 'neema'])],
  ['baraka', p(['grace', 'neema'])],
  ['idrisa', p(['neema'])],
  ['gone', p(['john', 'neema'], false)],
]);
const staff: Assigner = { uid: 'asha', role: 'staff', adminVerified: false };
const john: Assigner = { uid: 'john', role: 'manager', adminVerified: false };
const admin: Assigner = { uid: 'idrisa', role: 'admin', adminVerified: true };
const unverified: Assigner = { ...admin, adminVerified: false };

describe('mayAssign (PDD 2 matrix)', () => {
  test('staff assign only themselves', () => {
    expect(mayAssign(staff, 'asha', people.get('asha')!)).toBe(true);
    expect(mayAssign(staff, 'baraka', people.get('baraka')!)).toBe(false);
    expect(mayAssign(staff, 'john', people.get('john')!)).toBe(false);
  });

  test('managers assign themselves and their reporting tree only', () => {
    expect(mayAssign(john, 'john', people.get('john')!)).toBe(true);
    expect(mayAssign(john, 'asha', people.get('asha')!)).toBe(true);
    expect(mayAssign(john, 'baraka', people.get('baraka')!)).toBe(false);
    expect(mayAssign(john, 'neema', people.get('neema')!)).toBe(false);
  });

  test('verified admins assign anyone; unverified admins only their own tree', () => {
    expect(mayAssign(admin, 'baraka', people.get('baraka')!)).toBe(true);
    expect(mayAssign(unverified, 'baraka', people.get('baraka')!)).toBe(false);
    expect(mayAssign(unverified, 'idrisa', people.get('idrisa')!)).toBe(true);
  });
});

describe('adminVerifiedAt', () => {
  test('needs a record valid at the time of the action', () => {
    expect(adminVerifiedAt({ verifiedUntilMs: 2000 }, 1000)).toBe(true);
    expect(adminVerifiedAt({ verifiedUntilMs: 1000 }, 1000)).toBe(false);
    expect(adminVerifiedAt(undefined, 1000)).toBe(false);
    expect(adminVerifiedAt({ verifiedUntilMs: '9999' }, 1000)).toBe(false);
  });
});

describe('checkAssignment', () => {
  const base = { assigner: john, assigneeIds: ['asha'], participantIds: [] as string[], people, deptActive: true };
  test('allowed', () => expect(checkAssignment(base)).toBeNull());
  test('department must be active', () => expect(checkAssignment({ ...base, deptActive: false })).toBe('department-invalid'));
  test('assignees and participants must be active members', () => {
    expect(checkAssignment({ ...base, assigneeIds: ['gone'] })).toBe('assignee-inactive');
    expect(checkAssignment({ ...base, assigneeIds: ['nobody'] })).toBe('assignee-inactive');
    expect(checkAssignment({ ...base, participantIds: ['gone'] })).toBe('assignee-inactive');
  });
  test('permission', () => {
    expect(checkAssignment({ ...base, assigneeIds: ['asha', 'baraka'] })).toBe('assignee-not-allowed');
    expect(checkAssignment({ ...base, assigner: staff, assigneeIds: ['john'] })).toBe('assignee-not-allowed');
    expect(checkAssignment({ ...base, assigner: admin, assigneeIds: ['baraka', 'neema'] })).toBeNull();
  });
  test('shape', () => {
    expect(checkAssignment({ ...base, assigneeIds: [] })).toBe('validation');
    expect(checkAssignment({ ...base, assigneeIds: ['asha', 'asha'] })).toBe('validation');
    expect(checkAssignment({ ...base, assigneeIds: Array.from({ length: 51 }, (_, i) => `u${i}`) })).toBe('validation');
  });
});

describe('computeViewerIds', () => {
  const chains = new Map([['asha', ['john', 'neema']], ['baraka', ['grace', 'neema']]]);
  test('non-confidential: creator, assignees, participants and every assignee\'s chain, once each', () => {
    expect(computeViewerIds({ creatorId: 'john', assigneeIds: ['asha', 'baraka'], participantIds: ['rehema'], confidential: false }, chains))
      .toEqual(['john', 'asha', 'baraka', 'rehema', 'neema', 'grace']);
  });
  test('confidential: no managers, only creator, assignees and participants', () => {
    expect(computeViewerIds({ creatorId: 'rehema', assigneeIds: ['asha'], participantIds: ['baraka'], confidential: true }, chains))
      .toEqual(['rehema', 'asha', 'baraka']);
  });
});

describe('completionStatus (A-02, D-06)', () => {
  const t = {
    status: 'in_progress' as const, templateId: null, assignmentState: 'assigned', deleted: false,
    completionMode: 'all' as const, assigneeIds: ['a', 'b'], completedByIds: ['a'], needsCheck: false,
  };
  test('all mode waits for every current assignee', () => {
    expect(completionStatus(t)).toBeNull();
    expect(completionStatus({ ...t, completedByIds: ['b', 'a'] })).toBe('done');
    expect(completionStatus({ ...t, completedByIds: ['a', 'b'], needsCheck: true })).toBe('awaiting_check');
    // A finished person who is no longer an assignee does not count.
    expect(completionStatus({ ...t, assigneeIds: ['b', 'c'], completedByIds: ['a', 'b'] })).toBeNull();
  });
  test('any mode needs one', () => expect(completionStatus({ ...t, completionMode: 'any' })).toBe('done'));
  test('only active, assigned, simple, not deleted tasks', () => {
    const all = { ...t, completedByIds: ['a', 'b'] };
    expect(completionStatus({ ...all, status: 'done' })).toBeNull();
    expect(completionStatus({ ...all, status: 'awaiting_check' })).toBeNull();
    expect(completionStatus({ ...all, status: 'cancelled' })).toBeNull();
    expect(completionStatus({ ...all, templateId: 'purchase' })).toBeNull();
    expect(completionStatus({ ...all, assignmentState: 'pending' })).toBeNull();
    expect(completionStatus({ ...all, deleted: true })).toBeNull();
    expect(completionStatus({ ...all, status: 'blocked' })).toBe('done');
  });
});
