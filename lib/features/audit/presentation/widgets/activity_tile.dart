import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/audit_entry.dart';
import '../../../../shared/models/task_priority.dart';
import '../../../../shared/models/task_status.dart';
import '../../../../shared/widgets/enum_labels.dart';

/// Name of the person who acted: their name, "ATMS" for the system, or
/// "Someone" while the name is loading.
String actorName(
  String actorId,
  Map<String, AppUser> people,
  AppLocalizations l10n,
) {
  if (actorId.isEmpty) return l10n.activitySystemActor;
  return people[actorId]?.name ?? l10n.unknownPerson;
}

String? _statusLabel(Object? raw, AppLocalizations l10n) {
  try {
    return TaskStatus.fromFirestore(raw).label(l10n);
  } on FormatException {
    return null;
  }
}

String? _priorityLabel(Object? raw, AppLocalizations l10n) {
  try {
    return TaskPriority.fromFirestore(raw).label(l10n);
  } on FormatException {
    return null;
  }
}

String? _dateLabel(Object? raw, AppLocalizations l10n) {
  final DateTime? time = switch (raw) {
    Timestamp() => raw.toDate(),
    DateTime() => raw,
    String() => DateTime.tryParse(raw),
    num() => DateTime.fromMillisecondsSinceEpoch(raw.toInt()),
    _ => null,
  };
  if (time == null) return null;
  return DateFormat.yMMMd(l10n.localeName).add_Hm().format(time.toLocal());
}

String _reason(Map<String, Object?> after, String field) {
  final value = after[field];
  return value is String ? value : '';
}

/// One audit entry in plain, localised words (spec 4.11): who did what.
/// Values are shown only for fields every reader of the entry may see.
String activityText(
  AuditEntry entry,
  Map<String, AppUser> people,
  AppLocalizations l10n,
) {
  final actor = actorName(entry.actorId, people, l10n);
  final before = entry.before;
  final after = entry.after;
  switch (entry.action) {
    case AuditAction.taskCreated:
      return l10n.activityCreated(actor);
    case AuditAction.taskAssigned:
      return l10n.activityAssigned;
    case AuditAction.taskRejected:
      return l10n.activityRejected(
        assignmentErrorMessage(after['assignmentError'] as String?, l10n),
      );
    case AuditAction.taskReassigned:
      final ids = after['assigneeIds'];
      final names = ids is List
          ? ids
                .whereType<String>()
                .map((id) => people[id]?.name ?? l10n.unknownPerson)
                .join(', ') // l10n-ignore: list separator
          : '';
      return names.isEmpty
          ? l10n.activityReassignedNoNames(actor)
          : l10n.activityReassigned(actor, names);
    case AuditAction.statusChanged:
      final from = _statusLabel(before['status'], l10n);
      final to = _statusLabel(after['status'], l10n);
      if (to == null) return l10n.activityGeneric(actor);
      if (from == null) return l10n.activityStatusSet(actor, to);
      return l10n.activityStatusChanged(actor, from, to);
    case AuditAction.deadlineChanged:
      final from = _dateLabel(before['deadline'], l10n);
      final to = _dateLabel(after['deadline'], l10n);
      if (from == null || to == null) return l10n.activityDeadlineSet(actor);
      return l10n.activityDeadlineChanged(actor, from, to);
    case AuditAction.taskEdited:
      final fields = <String>[
        if (after.containsKey('title')) l10n.taskFieldTitle,
        if (after.containsKey('description')) l10n.taskFieldDescription,
        if (after.containsKey('priority'))
          _priorityLabel(after['priority'], l10n) == null
              ? l10n.taskFieldPriority
              : l10n.activityPriorityValue(
                  _priorityLabel(after['priority'], l10n)!,
                ),
        if (after.containsKey('needsCheck')) l10n.taskFieldNeedsCheck,
      ];
      return fields.isEmpty
          ? l10n.activityGeneric(actor)
          : l10n.activityEdited(
              actor,
              fields.join(', '), // l10n-ignore: list separator
            );
    case AuditAction.taskCancelled:
      final reason = _reason(after, 'cancelReason');
      return reason.isEmpty
          ? l10n.activityCancelledNoReason(actor)
          : l10n.activityCancelled(actor, reason);
    case AuditAction.taskDeleted:
      return l10n.activityDeleted(actor);
    case AuditAction.taskCompletedBy:
      return l10n.activityCompletedBy(actor);
    case AuditAction.checkReturned:
      final reason = _reason(after, 'returnReason');
      return reason.isEmpty
          ? l10n.activityReturnedNoReason(actor)
          : l10n.activityReturned(actor, reason);
    case AuditAction.userAdded:
      return l10n.activityUserAdded(actor);
    case AuditAction.userUpdated:
      return l10n.activityUserUpdated(actor);
    case AuditAction.userDeactivated:
      return l10n.activityUserDeactivated(actor);
    case AuditAction.other:
      return l10n.activityGeneric(actor);
  }
}

/// One line of an activity log: what happened, when, and whether it was
/// made offline.
class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.entry, required this.people});

  final AuditEntry entry;
  final Map<String, AppUser> people;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final at = entry.at;
    return ListTile(
      key: ValueKey('activity-${entry.id}'),
      dense: true,
      leading: const Icon(Icons.history),
      title: Text(activityText(entry, people, l10n)),
      subtitle: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (at != null)
            Text(
              DateFormat.yMMMd(l10n.localeName).add_Hm().format(at.toLocal()),
            ),
          if (entry.madeOffline)
            Row(
              key: const Key('madeOfflineMarker'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(child: Text(l10n.activityMadeOffline)),
              ],
            ),
        ],
      ),
    );
  }
}
