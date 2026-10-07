import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../constants/app_constants.dart';
import '../errors/app_failure.dart';
import '../errors/failure_mapper.dart';
import '../utils/logger.dart';
import 'app_config.dart';
import 'emulator_config.dart';

/// Outcome of start-up.
sealed class BootstrapResult {
  const BootstrapResult();
}

/// Firebase is initialised and ready.
final class BootstrapReady extends BootstrapResult {
  const BootstrapReady();
}

/// No Firebase options were provided at build time. The app starts and
/// shows the "App not configured" screen.
final class BootstrapNotConfigured extends BootstrapResult {
  const BootstrapNotConfigured();
}

/// Options were provided but Firebase failed to start. Shown with the same
/// "App not configured" screen; the cause is logged.
final class BootstrapFailed extends BootstrapResult {
  const BootstrapFailed(this.failure);

  final AppFailure failure;
}

/// Initialises Firebase from [config]. Never throws: every outcome is a
/// [BootstrapResult] so the app can always render something.
Future<BootstrapResult> bootstrap(AppConfig config) async {
  if (!config.isFirebaseConfigured) {
    AppLogger.warning(
      'Firebase options missing; starting in not-configured mode',
      context: {'env': config.environment.name},
    );
    return const BootstrapNotConfigured();
  }
  try {
    await Firebase.initializeApp(options: config.firebase.toFirebaseOptions());

    final firestore = FirebaseFirestore.instance;
    // Offline persistence (spec 4.9). Must be set before the first read.
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: AppConstants.firestoreCacheSizeBytes,
    );

    if (config.useFirebaseEmulator) {
      final host = resolveEmulatorHost(override: config.emulatorHostOverride);
      firestore.useFirestoreEmulator(host, EmulatorPorts.firestore);
      await FirebaseAuth.instance.useAuthEmulator(host, EmulatorPorts.auth);
      // NOT IMPLEMENTED (Sprint 3 / Sprint 5): connect the Functions
      // (EmulatorPorts.functions) and Storage (EmulatorPorts.storage)
      // emulators once `cloud_functions` and `firebase_storage` are added.
      // They are not dependencies in Sprint 0.
      AppLogger.info('Using Firebase emulators', context: {'host': host});
    }
    AppLogger.info(
      'Firebase initialised',
      context: {'env': config.environment.name},
    );
    return const BootstrapReady();
  } catch (error, stackTrace) {
    final failure = mapError(error, stackTrace);
    AppLogger.error(
      'Firebase initialisation failed',
      context: {'env': config.environment.name, 'code': failure.code},
      error: error,
      stackTrace: stackTrace,
    );
    return BootstrapFailed(failure);
  }
}
