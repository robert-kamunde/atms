/**
 * Deployment region, decided as africa-south1 (Johannesburg) in docs/DECISIONS.md D-03: the
 * nearest Google Cloud region to Tanzania, chosen with the Tanzania Personal Data Protection
 * Act 2022 in mind. Firestore's location cannot be changed after creation.
 */
export const REGION = process.env.ATMS_REGION ?? 'africa-south1';

/** The Firebase project the functions run in (set by the runtime and by the emulator). */
export function currentProjectId(): string {
  return process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT ?? '';
}

/** True only for the `demo-` projects used by the Firebase Emulator and tests. */
export function isEmulatorProject(id: string = currentProjectId()): boolean {
  return id.startsWith('demo-');
}

/** Largest organisation the server handles in one reporting-tree update (PDD 6: 1,000 users). */
export const MAX_ORG_USERS = 5000;
