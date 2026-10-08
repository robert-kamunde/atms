import 'package:atms/core/localization/l10n.dart';
import 'package:atms/core/localization/locale_provider.dart';
import 'package:atms/core/theme/app_theme.dart';
import 'package:atms/features/auth/domain/auth_state.dart';
import 'package:atms/features/auth/presentation/auth_providers.dart';
import 'package:atms/shared/models/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Both supported languages; widget tests run once per locale.
const testLocales = [AppLocales.english, AppLocales.swahili];

/// Localized strings for [locale] without a widget tree.
AppLocalizations l10nFor(Locale locale) => lookupAppLocalizations(locale);

/// A time far enough ahead that an admin second factor stays valid for the
/// whole test.
final DateTime farFuture = DateTime.utc(2100);

/// Override that puts the app in the signed-in state for [role]. Admins
/// have a valid second factor unless [adminVerified] is false.
Override signedInAs(UserRole role, {bool adminVerified = true}) =>
    authControllerProvider.overrideWithBuild(
      (ref, notifier) => AuthSignedIn(
        role,
        adminVerifiedUntil: role == UserRole.admin && adminVerified
            ? farFuture
            : null,
      ),
    );

/// Pumps [child] inside ProviderScope + MaterialApp with the ATMS theme and
/// localizations for [locale]. No Firebase is touched.
Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  required Locale locale,
  List<Override> overrides = const [],
}) async {
  // A typical small Android phone (360 x 740 dp).
  tester.view.physicalSize = const Size(1080, 2220);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocales.supported,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Text shown by the stub page at [path] in [pumpLocalizedRouter].
String stubPage(String path) => 'stub:$path';

/// Like [pumpLocalized], but [child] is the page at [initialPath] of a
/// [GoRouter] so `context.go` works. Every path in [otherPaths] is a stub
/// page that shows [stubPage].
Future<void> pumpLocalizedRouter(
  WidgetTester tester,
  Widget child, {
  required Locale locale,
  String initialPath = '/start',
  List<String> otherPaths = const [],
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(1080, 2220);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: initialPath,
    routes: [
      GoRoute(path: initialPath, builder: (_, _) => child),
      for (final path in otherPaths)
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text(stubPage(path))),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocales.supported,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
