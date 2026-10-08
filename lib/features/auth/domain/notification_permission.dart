/// Asking the phone for permission to show notifications (spec 4.1 step 4).
///
/// Registering the push token in `users/{uid}/private/devices` is Sprint 4
/// (notifications module); this only covers the permission prompt.
abstract interface class NotificationPermissionService {
  /// True when the phone has never been asked (so onboarding should show
  /// the notification screen). False when already answered or when the
  /// platform grants it without asking (Android 12 and older).
  Future<bool> needsPrompt();

  /// Shows the system permission dialog. Returns true when allowed.
  Future<bool> request();
}
