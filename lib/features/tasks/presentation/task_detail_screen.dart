import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/sync_banner.dart';
import '../../collaboration/presentation/attachments_section.dart';
import '../../collaboration/presentation/comments_section.dart';
import '../../workflows/presentation/widgets/step_tracker.dart';

/// Task detail (spec 4.3, 4.4, 4.7): summary, step tracker, comments,
/// attachments.
///
/// NOT IMPLEMENTED (Sprint 2): load the task by [taskId] (a missing or
/// forbidden task shows the same "not found" message — spec 4.8), status
/// buttons, activity feed. Sprint 3: Submit/Approve/Reject/Send back as
/// `TransitionRequest`s.
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.taskDetailTitle),
        actions: [
          IconButton(
            tooltip: l10n.actionEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(RoutePaths.taskEditFor(taskId)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SyncBanner(),
          SectionCard(
            icon: Icons.info_outline,
            title: l10n.taskSummaryTitle,
            child: Text(l10n.taskNotLoadedYet),
          ),
          const StepTracker(),
          const CommentsSection(),
          const AttachmentsSection(),
        ],
      ),
    );
  }
}
