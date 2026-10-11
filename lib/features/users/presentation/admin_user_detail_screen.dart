import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/enum_labels.dart';
import '../../../shared/widgets/failure_snackbar.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/domain/phone_number.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/presentation/email_sign_in_screen.dart' show looksLikeEmail;
import '../../departments/presentation/department_providers.dart';
import '../../departments/presentation/widgets/department_picker.dart';
import '../domain/user_repositories.dart';
import 'user_providers.dart';
import 'widgets/user_picker.dart';

/// Longest name and job title the editor accepts.
const int _maxTextLength = 100;

/// Admin: add or edit a person (spec 4.2): name, phone, email, role,
/// department, supervisor, job role, language and confidential access;
/// deactivate with confirmation. Saving calls `adminUpsertUser`, which
/// checks reporting loops, uniqueness and the department on the server, so
/// it needs a connection.
class AdminUserDetailScreen extends ConsumerWidget {
  const AdminUserDetailScreen({super.key, this.userId});

  /// Null when adding a new person.
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = userId;
    if (id == null) {
      return const _UserEditorForm(initial: null);
    }
    final data = ref.watch(userEditorDataProvider(id));
    return data.when(
      data: (value) => _UserEditorForm(initial: value),
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.adminUserDetailTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: Text(l10n.adminUserDetailTitle)),
        body: EmptyState(
          icon: Icons.error_outline,
          title: failureMessage(mapError(error, stackTrace), l10n),
          action: OutlinedButton(
            onPressed: () => ref.invalidate(userEditorDataProvider(id)),
            child: Text(l10n.actionRetry),
          ),
        ),
      ),
    );
  }
}

class _UserEditorForm extends ConsumerStatefulWidget {
  const _UserEditorForm({required this.initial});

  final UserEditorData? initial;

  @override
  ConsumerState<_UserEditorForm> createState() => _UserEditorFormState();
}

class _UserEditorFormState extends ConsumerState<_UserEditorForm> {
  final _formKey = GlobalKey<FormState>();
  late final AppUser? _user = widget.initial?.user;
  late final TextEditingController _name = TextEditingController(
    text: _user?.name ?? '',
  );
  late final TextEditingController _phone = TextEditingController(
    text: _localPhone(widget.initial?.contact?.phone),
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.initial?.contact?.email ?? '',
  );
  late final TextEditingController _jobRole = TextEditingController(
    text: _user?.jobRole ?? '',
  );
  late UserRole _role = _user?.role ?? UserRole.staff;
  late String? _deptId = _user?.deptId;
  late String? _supervisorId = _user?.supervisorId;
  late String _language = _user?.language ?? AppLocales.swahili.languageCode;
  late List<String> _confidentialDepts = [...?_user?.confidentialDepts];
  bool _busy = false;
  bool _deptMissing = false;

  /// The person already has an email, which cannot be removed (contract).
  late final bool _hadEmail = (widget.initial?.contact?.email ?? '').isNotEmpty;

  /// Shows a stored `+255712345678` as `0712 345 678`.
  static String _localPhone(String? e164) {
    if (e164 == null || !e164.startsWith(AppConstants.defaultDialCode)) {
      return e164 ?? '';
    }
    final local = e164.substring(AppConstants.defaultDialCode.length);
    if (local.length != 9) return e164;
    return '0${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
  }

  @override
  void initState() {
    super.initState();
    ref.read(departmentLookupProvider.notifier).ensure([
      _deptId,
      ..._confidentialDepts,
    ]);
    ref.read(userLookupProvider.notifier).ensure([_supervisorId]);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _jobRole.dispose();
    super.dispose();
  }

  String? _trimmedOrNull(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() => _deptMissing = _deptId == null);
    if (!valid || _deptId == null) return;
    // Saving without a supervisor makes this person the top of the
    // organisation and moves the current top under them (server rule).
    final becomesTop =
        _supervisorId == null && (_user == null || _user.supervisorId != null);
    if (becomesTop && !await _confirmTopPerson()) return;
    if (!mounted) return;
    final draft = UserDraft(
      uid: _user?.id,
      name: _name.text.trim(),
      phone: _phone.text.trim().isEmpty
          ? null
          : normaliseTanzanianPhone(_phone.text),
      email: _trimmedOrNull(_email),
      role: _role,
      deptId: _deptId!,
      supervisorId: _supervisorId,
      jobRole: _trimmedOrNull(_jobRole),
      language: _language,
      confidentialDepts: _confidentialDepts,
    );
    setState(() => _busy = true);
    try {
      final result = await ref.read(userEditorProvider.notifier).save(draft);
      if (!mounted) return;
      showMessageSnackBar(
        context,
        result.created ? l10n.userAddedMessage : l10n.savedMessage,
      );
      context.go(RoutePaths.adminUsers);
    } catch (error, stackTrace) {
      if (mounted) showFailureSnackBar(context, mapError(error, stackTrace));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmTopPerson() async {
    final l10n = context.l10n;
    final name = _name.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.topPersonWarningTitle),
        content: Text(l10n.topPersonWarningMessage(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('confirmTopPersonButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionContinueAnyway),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _deactivate(AppUser user) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deactivateUserTitle),
        content: Text(l10n.deactivateUserMessage(user.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('confirmDeactivateButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDeactivate),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final count = await ref
          .read(userEditorProvider.notifier)
          .deactivate(user.id);
      if (!mounted) return;
      showMessageSnackBar(context, l10n.userDeactivatedMessage(count));
      context.go(RoutePaths.adminUsers);
    } catch (error, stackTrace) {
      if (mounted) showFailureSnackBar(context, mapError(error, stackTrace));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDepartment() async {
    final dept = await showDepartmentPicker(
      context,
      title: context.l10n.userFieldDepartment,
    );
    if (dept == null || !mounted) return;
    ref.read(departmentLookupProvider.notifier).put(dept);
    setState(() {
      _deptId = dept.id;
      _deptMissing = false;
    });
  }

  Future<void> _pickSupervisor() async {
    final user = await showUserPicker(
      context,
      title: context.l10n.userFieldSupervisor,
      excludeIds: {?_user?.id},
    );
    if (user == null || !mounted) return;
    ref.read(userLookupProvider.notifier).put(user);
    setState(() => _supervisorId = user.id);
  }

  Future<void> _addConfidentialDept() async {
    final dept = await showDepartmentPicker(
      context,
      title: context.l10n.userFieldConfidentialAccess,
      excludeIds: _confidentialDepts.toSet(),
    );
    if (dept == null || !mounted) return;
    ref.read(departmentLookupProvider.notifier).put(dept);
    setState(() => _confidentialDepts = [..._confidentialDepts, dept.id]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final departments = ref.watch(departmentLookupProvider);
    final people = ref.watch(userLookupProvider);
    final user = _user;
    final isSelf =
        user != null && user.id == ref.watch(currentSessionProvider)?.uid;
    final supervisor = _supervisorId == null ? null : people[_supervisorId];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          user == null ? l10n.userCreateTitle : l10n.adminUserDetailTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (user != null && !user.active)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: StatusChip(label: l10n.labelInactive),
                ),
              ),
            SectionCard(
              title: l10n.userDetailsSection,
              icon: Icons.person_outline,
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('userNameField'),
                    controller: _name,
                    maxLength: _maxTextLength,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.userFieldName),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? l10n.validationNameRequired
                        : null,
                  ),
                  TextFormField(
                    key: const Key('userPhoneField'),
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.phoneNumberLabel,
                      hintText: l10n.phoneNumberHint,
                      helperText: l10n.userContactHelp,
                    ),
                    validator: (v) {
                      final phone = (v ?? '').trim();
                      if (phone.isEmpty) {
                        return _email.text.trim().isEmpty
                            ? l10n.validationPhoneOrEmail
                            : null;
                      }
                      return normaliseTanzanianPhone(phone) == null
                          ? l10n.errorInvalidPhone
                          : null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('userEmailField'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      hintText: l10n.optionalFieldHint,
                    ),
                    validator: (v) {
                      final email = (v ?? '').trim();
                      if (email.isEmpty) {
                        // The server refuses `email: null` once set.
                        return _hadEmail
                            ? l10n.errorEmailCannotBeRemoved
                            : null;
                      }
                      return looksLikeEmail(email)
                          ? null
                          : l10n.errorInvalidEmail;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('userJobRoleField'),
                    controller: _jobRole,
                    maxLength: _maxTextLength,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.userFieldJobRole,
                      hintText: l10n.optionalFieldHint,
                      helperText: l10n.userJobRoleHelp,
                    ),
                  ),
                ],
              ),
            ),
            SectionCard(
              title: l10n.userAccessSection,
              icon: Icons.shield_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<UserRole>(
                    key: const Key('userRoleField'),
                    initialValue: _role,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.userFieldRole),
                    items: [
                      for (final role in UserRole.values)
                        DropdownMenuItem(
                          value: role,
                          child: Text(role.label(l10n)),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _role = value ?? _role),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    key: const Key('userDepartmentTile'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.apartment_outlined),
                    title: Text(l10n.userFieldDepartment),
                    subtitle: Text(
                      _deptId == null
                          ? l10n.valueNotChosen
                          : departments[_deptId]?.name ?? l10n.valueNotLoaded,
                      style: _deptMissing
                          ? TextStyle(color: theme.colorScheme.error)
                          : null,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickDepartment,
                  ),
                  if (_deptMissing)
                    Text(
                      l10n.validationDepartmentRequired,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ListTile(
                    key: const Key('userSupervisorTile'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.supervisor_account_outlined),
                    title: Text(l10n.userFieldSupervisor),
                    subtitle: Text(
                      _supervisorId == null
                          ? l10n.userNoSupervisor
                          : supervisor?.name ?? l10n.valueNotLoaded,
                    ),
                    onTap: _pickSupervisor,
                    trailing: _supervisorId == null
                        ? const Icon(Icons.chevron_right)
                        : IconButton(
                            tooltip: l10n.actionClear,
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _supervisorId = null),
                          ),
                  ),
                  if (supervisor != null && !supervisor.active)
                    StatusChip(
                      label: l10n.labelSupervisorInactive,
                      warning: true,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.userLanguageLabel,
                    style: theme.textTheme.bodySmall,
                  ),
                  SegmentedButton<String>(
                    key: const Key('userLanguageField'),
                    segments: [
                      ButtonSegment(
                        value: AppLocales.swahili.languageCode,
                        label: Text(l10n.languageSwahili),
                      ),
                      ButtonSegment(
                        value: AppLocales.english.languageCode,
                        label: Text(l10n.languageEnglish),
                      ),
                    ],
                    selected: {_language},
                    onSelectionChanged: (value) =>
                        setState(() => _language = value.first),
                  ),
                ],
              ),
            ),
            SectionCard(
              title: l10n.userFieldConfidentialAccess,
              icon: Icons.lock_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.userConfidentialHelp),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final deptId in _confidentialDepts)
                        InputChip(
                          label: Text(
                            departments[deptId]?.name ?? l10n.valueNotLoaded,
                          ),
                          deleteButtonTooltipMessage: l10n.actionRemove,
                          onDeleted: () => setState(
                            () => _confidentialDepts = [
                              for (final d in _confidentialDepts)
                                if (d != deptId) d,
                            ],
                          ),
                        ),
                      ActionChip(
                        key: const Key('addConfidentialDeptButton'),
                        avatar: const Icon(Icons.add),
                        label: Text(l10n.actionAddDepartment),
                        onPressed: _addConfidentialDept,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    key: const Key('saveUserButton'),
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.actionSave),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user == null
                        ? l10n.userInviteNote
                        : l10n.needsConnectionNote,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (user != null && user.active && !isSelf) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      key: const Key('deactivateUserButton'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      onPressed: _busy ? null : () => _deactivate(user),
                      icon: const Icon(Icons.person_off_outlined),
                      label: Text(l10n.actionDeactivateUser),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
