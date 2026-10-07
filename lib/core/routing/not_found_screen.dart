import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/empty_state.dart';
import '../localization/l10n.dart';
import 'route_names.dart';

/// Shown for unknown routes. Uses the same "not found" wording as a missing
/// or forbidden task (spec 4.8).
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: EmptyState(
        icon: Icons.search_off,
        title: l10n.errorNotFound,
        action: FilledButton(
          onPressed: () => context.go(RoutePaths.tasks),
          child: Text(l10n.actionGoToTasks),
        ),
      ),
    );
  }
}
