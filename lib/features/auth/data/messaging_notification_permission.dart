import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/errors/failure_mapper.dart';
import '../domain/notification_permission.dart';

/// [NotificationPermissionService] backed by Firebase Cloud Messaging.
///
/// NOT IMPLEMENTED (Sprint 4): after permission is granted, get the FCM
/// token and store it in `users/{uid}/private/devices` (rules allow the
/// owner to write `fcmTokens` and `updatedAt`).
class MessagingNotificationPermission implements NotificationPermissionService {
  MessagingNotificationPermission(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Future<bool> needsPrompt() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.notDetermined;
    } catch (error, stackTrace) {
      throw mapError(error, stackTrace);
    }
  }

  @override
  Future<bool> request() async {
    try {
      final settings = await _messaging.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (error, stackTrace) {
      throw mapError(error, stackTrace);
    }
  }
}
