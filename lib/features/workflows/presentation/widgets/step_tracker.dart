import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_card.dart';

/// Step tracker for a workflow task (spec 4.4): done, current and upcoming
/// steps with names and dates.
///
/// NOT IMPLEMENTED (Sprint 3): steps come from the task's template version
/// and its transition history. Until then it shows the empty state for a
/// task without workflow steps.
class StepTracker extends StatelessWidget {
  const StepTracker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SectionCard(
      key: const Key('stepTrackerSection'),
      icon: Icons.linear_scale,
      title: l10n.stepTrackerTitle,
      child: EmptyState(
        compact: true,
        icon: Icons.account_tree_outlined,
        title: l10n.stepTrackerEmpty,
      ),
    );
  }
}
