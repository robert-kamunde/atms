/**
 * bootstrap-org: creates the FIRST organisation of an ATMS installation, with one department and
 * one admin (Firebase Auth account + custom claim { orgId } + user document + contact document).
 * See docs/SPRINT1_CONTRACT.md, "Organisation bootstrap". Everyone else is then added in the app
 * by that admin (adminUpsertUser), and departments and settings are edited there too.
 *
 * Usage (from functions/):
 *
 *   npm run bootstrap-org -- --project <firebase-project-id> \
 *     --org-id <id> --org-name "<name>" --dept-name "<first department>" \
 *     --admin-name "<name>" --email <admin e-mail> [--phone +255XXXXXXXXX] [--language en|sw] [--yes]
 *
 * - `--project` is required; nothing runs without it. Without `--yes` the script only prints what
 *   it would do (dry run).
 * - Real projects use Application Default Credentials (`gcloud auth application-default login`)
 *   with an account allowed to create Auth users and write Firestore.
 * - `demo-` projects run only against the emulators: start them first and export
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 and FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099.
 * - The admin needs an e-mail address for the admin code (D-01). The phone number is used for
 *   sign-in by SMS code; with e-mail only, the admin sets a password with "forgot password".
 * - The org defaults (time zone Africa/Dar_es_Salaam, working hours 08:00-17:00 Mon-Fri, reminders
 *   24 h and 1 h before, escalation after 24 h up to level 2, SMS on with a 50,000 TZS monthly cap,
 *   audit kept 3 years) are in src/auth/bootstrap.ts (defaultOrg) and can be changed in the app.
 * - It refuses to overwrite an organisation that already exists.
 *
 * The script runs the compiled code in lib/ (npm run bootstrap-org builds it first).
 */
import type * as Bootstrap from '../src/auth/bootstrap';

const USAGE = 'Usage: npm run bootstrap-org -- --project <id> --org-id <id> --org-name "<name>" --dept-name "<name>" '
  + '--admin-name "<name>" --email <email> [--phone +255XXXXXXXXX] [--language en|sw] [--yes]';

const FLAGS: Record<string, string> = {
  '--project': 'project', '--org-id': 'orgId', '--org-name': 'orgName', '--dept-name': 'deptName',
  '--admin-name': 'adminName', '--phone': 'phone', '--email': 'email', '--language': 'language',
};

function parse(argv: string[]): { values: Record<string, string | undefined>; yes: boolean } {
  const values: Record<string, string | undefined> = {};
  let yes = false;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--yes') { yes = true; continue; }
    const key = FLAGS[a];
    if (!key || i + 1 >= argv.length) throw new Error(`Unknown or incomplete argument: ${a}\n${USAGE}`);
    values[key] = argv[++i];
  }
  return { values, yes };
}

const mask = (v: string | null) => (v ? `${v.slice(0, 4)}***${v.slice(-3)}` : '(none)');

async function main(): Promise<void> {
  const { values, yes } = parse(process.argv.slice(2));
  const project = values.project;
  if (!project) throw new Error(`--project is required.\n${USAGE}`);

  const emulated = !!process.env.FIRESTORE_EMULATOR_HOST || !!process.env.FIREBASE_AUTH_EMULATOR_HOST;
  const bothEmulated = !!process.env.FIRESTORE_EMULATOR_HOST && !!process.env.FIREBASE_AUTH_EMULATOR_HOST;
  if (project.startsWith('demo-') && !bothEmulated) {
    throw new Error('demo- projects exist only in the emulators: set FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST.');
  }
  if (!project.startsWith('demo-') && emulated) {
    throw new Error(`Emulator variables are set but ${project} is a real project. Unset them or use a demo- project.`);
  }

  const lib = (await import('../lib/auth/bootstrap.js' as string)) as typeof Bootstrap;
  const args = lib.validateBootstrapArgs(values);
  const org = lib.defaultOrg(args.orgName);

  console.log(`ATMS bootstrap ${yes ? '' : '(dry run) '}for project ${project}${emulated ? ' [emulators]' : ''}`);
  console.log(`  Organisation  orgs/${args.orgId}: "${org.name}", ${org.timezone}, working hours ${org.workingHours.start}-${org.workingHours.end} Mon-Fri (${org.workingHoursEnabled ? 'on' : 'off'}),`);
  console.log(`                reminders ${org.reminderHours.join('h, ')}h before, escalation after ${org.escalationHours}h up to level ${org.escalationMaxLevel},`);
  console.log(`                SMS ${org.smsEnabled ? 'on' : 'off'} with cap ${org.smsMonthlyCap} TZS/month, audit kept ${org.auditRetentionYears} years`);
  console.log(`  Department    "${args.deptName}" (active)`);
  console.log(`  Admin         "${args.adminName}", phone ${mask(args.phone)}, e-mail ${mask(args.email)}, language ${args.language},`);
  console.log('                role admin, top of the reporting tree, Auth claim { orgId }');
  if (!yes) {
    console.log('\nNothing was written. Re-run with --yes to create these.');
    return;
  }

  const result = await lib.runBootstrap(project, args);
  console.log(`\nCreated orgs/${result.orgId}, department ${result.deptId}, admin uid ${result.adminUid}.`);
  console.log('Next: the admin signs in in the app (phone code, or e-mail after "forgot password"),');
  console.log('confirms the admin code sent by e-mail, then adds the other departments and users.');
}

main().catch((err: unknown) => {
  const e = err as { message?: string; details?: unknown };
  console.error(`bootstrap-org failed: ${e?.message ?? String(err)}`);
  process.exitCode = 1;
});
