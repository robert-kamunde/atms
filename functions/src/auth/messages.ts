/**
 * Texts sent outside the app in Sprint 1. They never contain task data (NOT-4). The Kiswahili
 * wording needs review by a native speaker with the rest of the translations (PDD 6, Languages).
 */
import { SMS_MAX_LENGTH } from '../notifications/sms/provider';
import type { EmailMessage } from '../notifications/email/provider';
import type { Language } from '../shared/model';

const INVITE: Record<Language, (org: string, url: string) => string> = {
  en: (org, url) => `You have been added to ${org} on ATMS. Download the app: ${url}`,
  sw: (org, url) => `Umeongezwa kwenye ${org} katika ATMS. Pakua programu: ${url}`,
};

/**
 * The invitation SMS (PDD 4.1 step 2). A long organisation name is shortened so the message
 * fits in one SMS; the link is never cut.
 */
export function invitationSms(language: Language, orgName: string, appDownloadUrl: string): string {
  if (!appDownloadUrl) throw new Error('APP_DOWNLOAD_URL is not configured');
  const build = INVITE[language];
  let org = orgName.trim();
  let text = build(org, appDownloadUrl);
  if (text.length > SMS_MAX_LENGTH) {
    const room = Math.max(1, org.length - (text.length - SMS_MAX_LENGTH) - 1);
    org = `${org.slice(0, room).trimEnd()}…`;
    text = build(org, appDownloadUrl);
  }
  return text;
}

export function adminCodeEmail(language: Language, to: string, code: string, minutes: number): EmailMessage {
  if (language === 'sw') {
    return {
      to,
      subject: 'Nambari ya uthibitisho ya msimamizi wa ATMS',
      text: `Nambari yako ya uthibitisho ya msimamizi wa ATMS ni ${code}. Itaisha baada ya dakika ${minutes}.\n\n`
        + 'Kama hukuiomba, usiitumie na mjulishe msimamizi mwingine wa ATMS.',
    };
  }
  return {
    to,
    subject: 'Your ATMS admin verification code',
    text: `Your ATMS admin verification code is ${code}. It expires in ${minutes} minutes.\n\n`
      + 'If you did not ask for it, do not use it and tell another ATMS administrator.',
  };
}

/** "robert@example.com" -> "r*****@example.com", shown in the app so the admin knows where to look. */
export function maskEmail(email: string): string {
  const at = email.lastIndexOf('@');
  if (at <= 0) return '***';
  const local = email.slice(0, at);
  return `${local[0]}${'*'.repeat(Math.max(3, local.length - 1))}${email.slice(at)}`;
}
