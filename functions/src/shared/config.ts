/**
 * Deployment region, decided as africa-south1 (Johannesburg) in docs/DECISIONS.md D-03: the
 * nearest Google Cloud region to Tanzania, chosen with the Tanzania Personal Data Protection
 * Act 2022 in mind. Firestore's location cannot be changed after creation.
 */
export const REGION = process.env.ATMS_REGION ?? 'africa-south1';
