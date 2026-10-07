/** Unit tests run without emulators; rules tests need the Firestore and Storage emulators (npm run test:rules). */
module.exports = {
  projects: [
    { displayName: 'unit', preset: 'ts-jest', testEnvironment: 'node', testMatch: ['<rootDir>/test/unit/**/*.test.ts'] },
    { displayName: 'rules', preset: 'ts-jest', testEnvironment: 'node', testMatch: ['<rootDir>/test/rules/**/*.test.ts'] },
  ],
};
