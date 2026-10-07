import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/bootstrap.dart';
import 'core/config/config_providers.dart';
import 'core/utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Never swallow errors: framework and async errors are logged.
  // (Crashlytics forwarding: Sprint 6.)
  FlutterError.onError = (details) {
    AppLogger.error(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.error(
      'Uncaught async error',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };

  final config = AppConfig.fromEnvironment();
  final result = await bootstrap(config);

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        bootstrapResultProvider.overrideWithValue(result),
      ],
      child: const AtmsApp(),
    ),
  );
}
