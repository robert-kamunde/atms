import 'package:firebase_core/firebase_core.dart';

/// Deployment environment, from `--dart-define=ATMS_ENV=dev|staging|prod`.
enum AppEnvironment {
  dev,
  staging,
  prod;

  static AppEnvironment parse(String raw) {
    for (final env in values) {
      if (env.name == raw.trim().toLowerCase()) return env;
    }
    // An unknown value is treated as the most restrictive environment so a
    // typo can never switch on development-only features in a release.
    return AppEnvironment.prod;
  }
}

/// Firebase client options passed at build time with `--dart-define`.
///
/// These values are *client identifiers*, not secrets, but real values are
/// still never committed: CI and developers pass them per environment.
class FirebaseClientOptions {
  const FirebaseClientOptions({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    required this.storageBucket,
    required this.iosBundleId,
  });

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String storageBucket;
  final String iosBundleId;

  /// The four options Firebase cannot start without. Storage bucket and iOS
  /// bundle id are optional at start-up.
  bool get isComplete =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      projectId.isNotEmpty;

  FirebaseOptions toFirebaseOptions() => FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket.isEmpty ? null : storageBucket,
    iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
  );
}

/// Build-time configuration of the app.
///
/// Example:
/// ```sh
/// flutter run \
///   --dart-define=ATMS_ENV=dev \
///   --dart-define=USE_FIREBASE_EMULATOR=true \
///   --dart-define=FIREBASE_API_KEY=... \
///   --dart-define=FIREBASE_APP_ID=... \
///   --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
///   --dart-define=FIREBASE_PROJECT_ID=... \
///   --dart-define=FIREBASE_STORAGE_BUCKET=... \
///   --dart-define=FIREBASE_IOS_BUNDLE_ID=...
/// ```
/// Optional: `--dart-define=FIREBASE_EMULATOR_HOST=192.168.1.20` to reach
/// emulators running on another machine (e.g. from a physical phone).
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.useFirebaseEmulator,
    required this.firebase,
    this.emulatorHostOverride = '',
  });

  /// Reads every value from `--dart-define`. Missing values become empty
  /// strings so that the app can still start and show the
  /// "App not configured" screen instead of crashing.
  factory AppConfig.fromEnvironment() => AppConfig(
    environment: AppEnvironment.parse(
      const String.fromEnvironment('ATMS_ENV', defaultValue: 'dev'),
    ),
    useFirebaseEmulator: const bool.fromEnvironment('USE_FIREBASE_EMULATOR'),
    emulatorHostOverride: const String.fromEnvironment(
      'FIREBASE_EMULATOR_HOST',
    ),
    firebase: const FirebaseClientOptions(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
      appId: String.fromEnvironment('FIREBASE_APP_ID'),
      messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
      projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
      storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
    ),
  );

  /// Configuration with no Firebase options, used by tests and as the
  /// provider default.
  static const AppConfig unconfigured = AppConfig(
    environment: AppEnvironment.dev,
    useFirebaseEmulator: false,
    firebase: FirebaseClientOptions(
      apiKey: '',
      appId: '',
      messagingSenderId: '',
      projectId: '',
      storageBucket: '',
      iosBundleId: '',
    ),
  );

  final AppEnvironment environment;
  final bool useFirebaseEmulator;
  final FirebaseClientOptions firebase;
  final String emulatorHostOverride;

  bool get isFirebaseConfigured => firebase.isComplete;
}
