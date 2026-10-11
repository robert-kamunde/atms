import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import '../utils/logger.dart';

/// How long start-up waits for App Check before carrying on without it.
const Duration _appCheckActivationLimit = Duration(seconds: 5);

/// Turns on Firebase App Check (D-04: monitor mode).
///
/// * Release builds use Play Integrity (Android) and App Attest with
///   DeviceCheck fallback (iOS).
/// * Debug and profile builds use the debug provider; the debug token is
///   printed in the device log and must be registered in the Firebase
///   console (docs/DEVELOPMENT.md) for the backend's App Check metrics.
///
/// Monitor mode means a failure here must never stop the app: phones
/// without Google Play services (common in Tanzania) still work, the
/// backend only logs requests without a valid token, and the Security Rules
/// remain the real protection. Errors are logged, never thrown.
Future<void> activateAppCheck({bool release = kReleaseMode}) async {
  try {
    await FirebaseAppCheck.instance
        .activate(
          providerAndroid: release
              ? const AndroidPlayIntegrityProvider()
              : const AndroidDebugProvider(),
          providerApple: release
              ? const AppleAppAttestWithDeviceCheckFallbackProvider()
              : const AppleDebugProvider(),
        )
        .timeout(_appCheckActivationLimit);
    AppLogger.info('App Check activated', context: {'release': release});
  } catch (error, stackTrace) {
    AppLogger.warning(
      'App Check activation failed; continuing (monitor mode, D-04)',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
