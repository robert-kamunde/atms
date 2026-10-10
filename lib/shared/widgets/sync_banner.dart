import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/l10n.dart';
import '../../core/theme/status_colors.dart';
import '../providers/sync_providers.dart';
import '../services/sync_status_source.dart';

/// Offline / sync banner (spec 4.9 step 2). Hidden while the state is
/// unknown, so it never claims something it has not checked.
///
/// "All changes saved" shows for [syncedVisibleFor] after the phone was
/// offline or syncing, then the banner hides; a phone that was in sync all
/// along shows nothing.
class SyncBanner extends ConsumerStatefulWidget {
  const SyncBanner({super.key});

  static const Duration syncedVisibleFor = Duration(seconds: 4);

  @override
  ConsumerState<SyncBanner> createState() => _SyncBannerState();
}

class _SyncBannerState extends ConsumerState<SyncBanner> {
  SyncState _shown = SyncState.unknown;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    final current = ref.read(syncStateProvider).value;
    if (current == SyncState.offline || current == SyncState.syncing) {
      _shown = current!;
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onState(SyncState? previous, SyncState next) {
    _hideTimer?.cancel();
    if (next == SyncState.synced) {
      final wasWorking =
          _shown == SyncState.offline || _shown == SyncState.syncing;
      if (!wasWorking) {
        setState(() => _shown = SyncState.unknown);
        return;
      }
      setState(() => _shown = SyncState.synced);
      _hideTimer = Timer(SyncBanner.syncedVisibleFor, () {
        if (mounted) setState(() => _shown = SyncState.unknown);
      });
      return;
    }
    setState(() => _shown = next);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<SyncState>>(syncStateProvider, (previous, next) {
      final value = next.value;
      if (value != null) _onState(previous?.value, value);
    });
    return SyncBannerView(state: _shown);
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
        key: const Key('syncBanner'),
        color: color,
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
    );
  }
}
