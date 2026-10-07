import '../../core/localization/l10n.dart';
import '../models/task_priority.dart';
import '../models/task_status.dart';
import '../models/user_role.dart';

/// Localized labels for model enums. Enums never carry UI text themselves.
extension TaskStatusLabel on TaskStatus {
  String label(AppLocalizations l10n) => switch (this) {
    TaskStatus.todo => l10n.statusTodo,
    TaskStatus.inProgress => l10n.statusInProgress,
    TaskStatus.blocked => l10n.statusBlocked,
    TaskStatus.done => l10n.statusDone,
    TaskStatus.cancelled => l10n.statusCancelled,
  };
}

extension TaskPriorityLabel on TaskPriority {
  String label(AppLocalizations l10n) => switch (this) {
    TaskPriority.low => l10n.priorityLow,
    TaskPriority.medium => l10n.priorityMedium,
    TaskPriority.high => l10n.priorityHigh,
    TaskPriority.urgent => l10n.priorityUrgent,
  };
}

extension UserRoleLabel on UserRole {
  String label(AppLocalizations l10n) => switch (this) {
    UserRole.admin => l10n.roleAdmin,
    UserRole.manager => l10n.roleManager,
    UserRole.staff => l10n.roleStaff,
  };
}
