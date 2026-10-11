import { validateCodeInput, validateEmptyInput, validateUidInput, validateUpsertInput } from '../../src/auth/validation';
import { AtmsError, ErrorCode } from '../../src/shared/errors';

const valid = {
  name: ' Asha Mushi ', phone: '+255712345678', email: null, role: 'staff', deptId: 'FIN',
  supervisorId: 'john', jobRole: null, language: 'sw', confidentialDepts: [],
};

function fieldOf(fn: () => unknown): string | undefined {
  try {
    fn();
  } catch (e) {
    expect(e).toBeInstanceOf(AtmsError);
    expect((e as AtmsError).code).toBe(ErrorCode.validation);
    return (e as AtmsError).details.field as string;
  }
  throw new Error('expected a validation error');
}

describe('adminUpsertUser input', () => {
  test('a valid input is normalised', () => {
    expect(validateUpsertInput({ ...valid, email: ' Asha@Example.COM ', confidentialDepts: ['HR', 'HR'] })).toEqual({
      ...valid, name: 'Asha Mushi', email: 'asha@example.com', confidentialDepts: ['HR'],
    });
  });

  test('a phone number or an e-mail is required', () => {
    expect(fieldOf(() => validateUpsertInput({ ...valid, phone: null, email: null }))).toBe('phone');
    expect(validateUpsertInput({ ...valid, phone: null, email: 'a@b.co' }).email).toBe('a@b.co');
  });

  test.each([
    ['phone', '0712345678'], ['phone', '+254712345678'], ['phone', '+2557123'], ['email', 'not-an-email'],
    ['role', 'owner'], ['language', 'fr'], ['name', '   '], ['name', 'x'.repeat(101)], ['deptId', 'a/b'],
    ['supervisorId', ''], ['jobRole', ''], ['confidentialDepts', 'HR'], ['uid', 'x/y'],
  ])('rejects a bad %s', (field, value) => {
    expect(fieldOf(() => validateUpsertInput({ ...valid, [field]: value }))).toBe(field);
  });

  test('unknown fields and missing fields are refused', () => {
    expect(fieldOf(() => validateUpsertInput({ ...valid, active: true }))).toBe('active');
    expect(fieldOf(() => validateUpsertInput({ ...valid, managerChain: [] }))).toBe('managerChain');
    const { supervisorId: _s, ...noSup } = valid;
    expect(fieldOf(() => validateUpsertInput(noSup))).toBe('supervisorId');
    expect(fieldOf(() => validateUpsertInput(null))).toBe('input');
  });

  test('a person cannot be their own supervisor', () => {
    expect(fieldOf(() => validateUpsertInput({ ...valid, uid: 'asha', supervisorId: 'asha' }))).toBe('supervisorId');
  });
});

describe('other inputs', () => {
  test('deactivateUser takes a uid only', () => {
    expect(validateUidInput({ uid: 'asha' })).toEqual({ uid: 'asha' });
    expect(fieldOf(() => validateUidInput({ uid: 'asha', extra: 1 }))).toBe('extra');
  });
  test('verifyAdminCode takes 6 digits', () => {
    expect(validateCodeInput({ code: '012345' })).toEqual({ code: '012345' });
    expect(fieldOf(() => validateCodeInput({ code: '12345' }))).toBe('code');
    expect(fieldOf(() => validateCodeInput({ code: 123456 }))).toBe('code');
  });
  test('sendAdminCode takes nothing', () => {
    expect(() => validateEmptyInput({})).not.toThrow();
    expect(() => validateEmptyInput(undefined)).not.toThrow();
    expect(fieldOf(() => validateEmptyInput({ to: 'x@y.z' }))).toBe('input');
  });
});
