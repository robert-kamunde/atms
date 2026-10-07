/**
 * Deployment region. DECISION PENDING (docs/PROJECT_STATUS.md, D6): the region decides
 * where personal data is stored under the Tanzania Personal Data Protection Act 2022.
 * europe-west1 is a placeholder; Firestore's location cannot be changed after creation.
 */
export const REGION = process.env.ATMS_REGION ?? 'europe-west1';
