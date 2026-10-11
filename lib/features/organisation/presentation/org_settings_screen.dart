import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure_mapper.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/failure_snackbar.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/sync_banner.dart';
import '../domain/org_settings.dart';
import 'org_providers.dart';

/// Admin: organisation settings (spec 4.2, 4.5, 4.6): working days and
/// hours, reminder times, escalation delay and levels, time zone (shown
/// only), SMS on/off and monthly cap. Only changed fields are written,
/// with `updatedAt` (server time), exactly as the rules allow. Works
/// offline: the change is kept on the phone and synced later.
class OrgSettingsScreen extends ConsumerWidget {
  const OrgSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(orgSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminSettingsTitle)),
      body: Column(
        children: [
          const SyncBanner(),
          Expanded(
            child: settings.when(
              data: (value) => value == null
                  ? EmptyState(
                      icon: Icons.error_outline,
                      title: l10n.errorNotFound,
                    )
                  : _OrgSettingsForm(initial: value),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => EmptyState(
                icon: Icons.error_outline,
                title: failureMessage(mapError(error, stackTrace), l10n),
                action: OutlinedButton(
                  onPressed: () => ref.invalidate(orgSettingsProvider),
                  child: Text(l10n.actionRetry),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrgSettingsForm extends ConsumerStatefulWidget {
  const _OrgSettingsForm({required this.initial});

  final OrgSettings initial;

  @override
  ConsumerState<_OrgSettingsForm> createState() => _OrgSettingsFormState();
}

class _OrgSettingsFormState extends ConsumerState<_OrgSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late OrgSettings _original = widget.initial;
  late bool _workingHoursEnabled = _original.workingHoursEnabled;
  late Set<int> _days = _original.workingHours.days.toSet();
  late String _start = _original.workingHours.start;
  late String _end = _original.workingHours.end;
  late bool _smsEnabled = _original.smsEnabled;
  late final TextEditingController _reminders = TextEditingController(
    text: _original.reminderHours.join(', '), // l10n-ignore: number list
  );
  late final TextEditingController _escalationHours = TextEditingController(
    text: '${_original.escalationHours}',
  );
  late final TextEditingController _escalationLevels = TextEditingController(
    text: '${_original.escalationMaxLevel}',
  );
  late final TextEditingController _smsCap = TextEditingController(
    text: '${_original.smsMonthlyCap}',
  );
  bool _busy = false;
  bool _daysMissing = false;

  @override
  void didUpdateWidget(_OrgSettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A newer version arrived (another admin, or our own synced write):
    // compare future edits against it.
    if (widget.initial != oldWidget.initial) _original = widget.initial;
  }

  @override
  void dispose() {
    _reminders.dispose();
    _escalationHours.dispose();
    _escalationLevels.dispose();
    _smsCap.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool start}) async {
    final current = parseClock(start ? _start : _end);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current?.hour ?? 8,
        minute: current?.minute ?? 0,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final value = formatClock(picked.hour, picked.minute);
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  String? _intValidator(String? value, {required int min, required int max}) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null || parsed < min || parsed > max) {
      return context.l10n.validationWholeNumberRange(min, max);
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() => _daysMissing = _days.isEmpty);
    if (!valid || _days.isEmpty) return;
    final edited = _original.copyWith(
      workingHoursEnabled: _workingHoursEnabled,
      workingHours: WorkingHours(
        start: _start,
        end: _end,
        days: _days.toList()..sort(),
      ),
      reminderHours: parseReminderHours(_reminders.text),
      escalationHours: int.parse(_escalationHours.text.trim()),
      escalationMaxLevel: int.parse(_escalationLevels.text.trim()),
      smsEnabled: _smsEnabled,
      smsMonthlyCap: int.parse(_smsCap.text.trim()),
    );
    setState(() => _busy = true);
    try {
      final outcome = await ref
          .read(orgSettingsEditorProvider.notifier)
          .save(_original, edited);
      if (!mounted) return;
      if (outcome == null) {
        showMessageSnackBar(context, l10n.noChangesMessage);
      } else {
        _original = edited;
        showWriteOutcomeSnackBar(context, outcome);
      }
    } catch (error, stackTrace) {
      if (mounted) showFailureSnackBar(context, mapError(error, stackTrace));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dayLabels = [
      l10n.dayMon,
      l10n.dayTue,
      l10n.dayWed,
      l10n.dayThu,
      l10n.dayFri,
      l10n.daySat,
      l10n.daySun,
    ];
    final digitsOnly = [FilteringTextInputFormatter.digitsOnly];
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SectionCard(
            title: l10n.settingWorkingHours,
            icon: Icons.schedule,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  key: const Key('workingHoursSwitch'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingWorkingHoursEnabled),
                  subtitle: Text(l10n.settingWorkingHoursEnabledHelp),
                  value: _workingHoursEnabled,
                  onChanged: (v) => setState(() => _workingHoursEnabled = v),
                ),
                Text(l10n.settingWorkingDays, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (var day = 1; day <= 7; day++)
                      FilterChip(
                        key: ValueKey('day-$day'),
                        label: Text(dayLabels[day - 1]),
                        selected: _days.contains(day),
                        onSelected: (selected) => setState(() {
                          _days = {..._days};
                          selected ? _days.add(day) : _days.remove(day);
                          _daysMissing = _days.isEmpty;
                        }),
                      ),
                  ],
                ),
                if (_daysMissing)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.validationWorkingDaysRequired,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ListTile(
                  key: const Key('workStartTile'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.wb_sunny_outlined),
                  title: Text(l10n.settingWorkStart),
                  subtitle: Text(_start),
                  onTap: () => _pickTime(start: true),
                ),
                ListTile(
                  key: const Key('workEndTile'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.nights_stay_outlined),
                  title: Text(l10n.settingWorkEnd),
                  subtitle: Text(_end),
                  onTap: () => _pickTime(start: false),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.public),
                  title: Text(l10n.settingTimeZone),
                  subtitle: Text(
                    _original.timezone == OrgSettings.defaultTimezone
                        ? l10n.timeZoneEastAfrica(_original.timezone)
                        : _original.timezone,
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            title: l10n.settingRemindersSection,
            icon: Icons.alarm,
            child: Column(
              children: [
                TextFormField(
                  key: const Key('reminderHoursField'),
                  controller: _reminders,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.settingReminderTimes,
                    helperText: l10n.settingReminderHoursHelp,
                  ),
                  validator: (v) => parseReminderHours(v ?? '') == null
                      ? l10n.validationReminderHours(OrgSettings.maxHours)
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('escalationHoursField'),
                  controller: _escalationHours,
                  keyboardType: TextInputType.number,
                  inputFormatters: digitsOnly,
                  decoration: InputDecoration(
                    labelText: l10n.settingEscalationDelay,
                    helperText: l10n.settingEscalationDelayHelp,
                  ),
                  validator: (v) =>
                      _intValidator(v, min: 1, max: OrgSettings.maxHours),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('escalationLevelsField'),
                  controller: _escalationLevels,
                  keyboardType: TextInputType.number,
                  inputFormatters: digitsOnly,
                  decoration: InputDecoration(
                    labelText: l10n.settingEscalationLevels,
                    helperText: l10n.settingEscalationLevelsHelp,
                  ),
                  validator: (v) => _intValidator(
                    v,
                    min: 1,
                    max: OrgSettings.maxEscalationLevel,
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            title: l10n.settingSmsSection,
            icon: Icons.sms_outlined,
            child: Column(
              children: [
                SwitchListTile(
                  key: const Key('smsSwitch'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingSmsEnabled),
                  subtitle: Text(l10n.settingSmsEnabledHelp),
                  value: _smsEnabled,
                  onChanged: (v) => setState(() => _smsEnabled = v),
                ),
                TextFormField(
                  key: const Key('smsCapField'),
                  controller: _smsCap,
                  keyboardType: TextInputType.number,
                  inputFormatters: digitsOnly,
                  decoration: InputDecoration(
                    labelText: l10n.settingSmsCap,
                    helperText: l10n.settingSmsCapHelp,
                  ),
                  validator: (v) => _intValidator(v, min: 0, max: 1000000000),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: FilledButton(
              key: const Key('saveSettingsButton'),
              onPressed: _busy ? null : _save,
              child: Text(l10n.actionSave),
            ),
          ),
        ],
      ),
    );
  }
}
