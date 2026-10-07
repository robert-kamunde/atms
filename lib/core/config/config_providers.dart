import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';
import 'bootstrap.dart';

/// Build-time configuration. Overridden in `main.dart` with
/// `AppConfig.fromEnvironment()`; tests override it as needed.
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.unconfigured);

/// Result of [bootstrap]. Overridden in `main.dart`. The default is "not
/// configured" so widget tests never touch Firebase.
final bootstrapResultProvider = Provider<BootstrapResult>(
  (ref) => const BootstrapNotConfigured(),
);
