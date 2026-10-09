import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failure_mapper.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/enum_labels.dart';
import '../../../shared/widgets/failure_snackbar.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../auth/presentation/auth_providers.dart';

/// More tab: profile, language, sign out, plus manager and admin areas.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final role = ref.watch(currentRoleProvider) ?? UserRole.staff;
    final locale = ref.watch(localeProvider);
    final user = ref.watch(currentSessionProvider)?.user;

    Widget link(IconData icon, String label, String path) => ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(path),
    );

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreTitle)),
      body: ListView(
        children: [
          header(l10n.profileSection),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.name ?? l10n.profileSignedInAs(role.label(l10n))),
            subtitle: user == null
                ? null
                : Text(
                    [
                      role.label(l10n),
                      ?user.jobRole,
                    ].join(' · '), // l10n-ignore: separator
                  ),
          ),
          header(l10n.languageSection),
          LanguageSelector(
            selected: locale,
            onChanged: (value) async {
              try {
                await ref
                    .read(authControllerProvider.notifier)
                    .changeLanguage(value);
              } catch (error, stackTrace) {
                if (context.mounted) {
                  showFailureSnackBar(context, mapError(error, stackTrace));
                }
              }
            },
          ),
          if (role.canSeeTeam) ...[
            header(l10n.managerSection),
            link(
              Icons.groups_outlined,
              l10n.teamTasksTitle,
              RoutePaths.teamTasks,
            ),
            link(
              Icons.summarize_outlined,
              l10n.reportsTitle,
              RoutePaths.reports,
            ),
          ],
          if (role.isAdmin) ...[
            header(l10n.adminSection),
            link(
              Icons.apartment_outlined,
              l10n.adminDepartmentsTitle,
              RoutePaths.adminDepartments,
            ),
            link(
              Icons.people_outline,
              l10n.adminUsersTitle,
              RoutePaths.adminUsers,
            ),
            link(
              Icons.account_tree_outlined,
              l10n.adminReportingTreeTitle,
              RoutePaths.adminReportingTree,
            ),
            link(
              Icons.view_list_outlined,
              l10n.adminTemplatesTitle,
              RoutePaths.adminTemplates,
            ),
            link(Icons.tune, l10n.adminSettingsTitle, RoutePaths.adminSettings),
            link(Icons.history, l10n.adminAuditTitle, RoutePaths.adminAudit),
            link(
              Icons.admin_panel_settings_outlined,
              l10n.adminVerifyTitle,
              RoutePaths.adminVerify,
            ),
          ],
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.actionSignOut),
            onTap: () async {
              try {
                await ref.read(authControllerProvider.notifier).signOut();
              } catch (error, stackTrace) {
                if (context.mounted) {
                  showFailureSnackBar(context, mapError(error, stackTrace));
                }
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
