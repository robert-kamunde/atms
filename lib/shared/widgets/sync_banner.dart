import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/l10n.dart';
import '../../core/theme/status_colors.dart';
import '../providers/sync_providers.dart';
import '../services/sync_status_source.dart';

/// Offline / sync banner (spec 4.9 step 2). Hidden while the state is
/// unknown, so it never claims something it has not checked.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncStateProvider).value ?? SyncState.unknown;
    return SyncBannerView(state: state);
  }
}

/// Stateless view of the banner, for any [SyncState].
class SyncBannerView extends StatelessWidget {
  const SyncBannerView({super.key, required this.state});

  final SyncState state;

  @override
  Widget build(BuildContext context) {
    if (state == SyncState.unknown) return const SizedBox.shrink();
    final l10n = context.l10n;
    final colors = context.atmsColors;
    final (IconData icon, String text, Color color) = switch (state) {
      // Unreachable: handled above. Kept so the switch stays exhaustive.
      SyncState.unknown => (Icons.sync, l10n.syncSyncing, colors.syncing),
      SyncState.offline => (Icons.cloud_off, l10n.syncOffline, colors.offline),
      SyncState.syncing => (Icons.sync, l10n.syncSyncing, colors.syncing),
      SyncState.synced => (Icons.cloud_done, l10n.syncAllSaved, colors.synced),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: color,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
