import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/errors/failure_messages.dart';
import 'core/localization/l10n.dart';
import 'core/localization/locale_provider.dart';
import 'core/routing/app_router.dart';
import 'core/services/offline_write.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'shared/widgets/failure_snackbar.dart';

/// Root widget: router, theme, and English/Kiswahili localization.
///
/// Also re-checks the session policy whenever the app comes back to the
/// foreground (30 days, 7 for admins) and shows a message when a change
/// saved offline is refused by the server after syncing.
class AtmsApp extends ConsumerStatefulWidget {
  const AtmsApp({super.key});

  @override
  ConsumerState<AtmsApp> createState() => _AtmsAppState();
}

class _AtmsAppState extends ConsumerState<AtmsApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(authControllerProvider.notifier).checkSession(),
    );
    lateWriteFailureHandler = (failure) {
      final messenger = rootScaffoldMessengerKey.currentState;
      final context = rootScaffoldMessengerKey.currentContext;
      if (messenger == null || context == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.offlineChangeRefused(
              failureMessage(failure, context.l10n),
            ),
          ),
        ),
      );
    };
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    lateWriteFailureHandler = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: ref.watch(routerProvider),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocales.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
