import 'package:flutter/foundation.dart';

/// Ports of the Firebase Emulator Suite (must match `firebase.json`).
abstract final class EmulatorPorts {
  static const int auth = 9099;
  static const int firestore = 8080;
  static const int functions = 5001;
  static const int storage = 9199;
}

/// Host the app uses to reach the emulators.
///
/// * An explicit `FIREBASE_EMULATOR_HOST` define wins (physical phone on
///   the same Wi-Fi as the developer's computer).
/// * Android emulator: `10.0.2.2` is the host computer's loopback.
/// * Everything else (iOS simulator, desktop, tests): `localhost`.
///
/// A physical Android phone without the override would also get
/// `10.0.2.2`; detecting emulator vs device needs `device_info_plus`,
/// which we avoid adding in Sprint 0.
String resolveEmulatorHost({
  required String override,
  TargetPlatform? platform,
  bool isWeb = kIsWeb,
}) {
  if (override.isNotEmpty) return override;
  final target = platform ?? defaultTargetPlatform;
  if (!isWeb && target == TargetPlatform.android) return '10.0.2.2';
  return 'localhost';
}
