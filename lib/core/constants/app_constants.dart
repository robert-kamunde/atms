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
}
