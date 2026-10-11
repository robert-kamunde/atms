/// App-wide constants that are not user-facing text.
///
/// User-facing text never lives here: it belongs in the ARB files under
/// `lib/core/localization/arb/`.
abstract final class AppConstants {
  /// Maximum number of documents any list screen loads at once.
  ///
  /// Spec section 8 (cost at scale): "paginate lists (20 tasks at a time)".
  /// Every repository list query must go through `PaginatedSource` in
  /// `lib/shared/services/paginated_query.dart`, which enforces this cap.
  static const int pageSize = 20;

  /// Minimum size of anything the user can tap (Material accessibility
  /// guideline, also important on small low-end phones).
  static const double minTapTarget = 48;

  /// Firestore offline cache size. 100 MB keeps a full working day of tasks,
  /// comments and metadata on a 2 GB RAM phone without filling storage.
  static const int firestoreCacheSizeBytes = 100 * 1024 * 1024;

  /// Default country calling code for phone sign-in (Tanzania).
  static const String defaultDialCode = '+255';

  /// Region of the callable Cloud Functions (D-03; must match
  /// `functions/src/shared/config.ts` REGION).
  static const String functionsRegion = 'africa-south1';

  /// How long a callable may take before the app reports that it needs a
  /// connection. Callables are online-only (ARCHITECTURE section 1), so the
  /// app must not hang while offline.
  static const Duration callableTimeout = Duration(seconds: 20);

  /// How long an offline-capable Firestore write is awaited before the app
  /// tells the user it is saved on the phone and will sync later.
  static const Duration offlineWriteWait = Duration(seconds: 3);

  /// Seconds before the user may ask for another SMS or email code.
  static const Duration resendCodeDelay = Duration(seconds: 60);

  /// Version of the privacy notice in the ARB files. Bump it when the
  /// consent text changes so every user is asked to accept it again.
  static const String consentVersion = '2026-10';

  /// How often a signed-in session is re-checked against the session
  /// policy while the app stays open (it is also checked on resume).
  static const Duration sessionCheckInterval = Duration(minutes: 15);
}
