/**
 * Unit tests run without emulators; rules tests need the Firestore and Storage emulators
 * (npm run test:rules); integration tests need the Auth and Firestore emulators
 * (npm run test:integration).
 */
module.exports = {
  projects: [
    { displayName: 'unit', preset: 'ts-jest', testEnvironment: 'node', testMatch: ['<rootDir>/test/unit/**/*.test.ts'] },
    { displayName: 'rules', preset: 'ts-jest', testEnvironment: 'node', testMatch: ['<rootDir>/test/rules/**/*.test.ts'] },
    {
      displayName: 'integration',
      preset: 'ts-jest',
      testEnvironment: 'node',
      testMatch: ['<rootDir>/test/integration/**/*.test.ts'],
      // firebase-admin/auth loads jose, which is ESM-only and cannot be required by Jest. The
      // handlers never verify tokens, so a stub that throws if it is ever used stands in for it.
      moduleNameMapper: { '^jose$': '<rootDir>/test/stubs/jose.js' },
    },
  ],
};
