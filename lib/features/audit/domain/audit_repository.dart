import '../../../shared/models/audit_entry.dart';
import '../../../shared/services/paginated_query.dart';

/// The audit log (read only; only the server writes it, spec 4.11).
abstract interface class AuditRepository {
  /// Entries for one task, newest first. Verified admins read with the
  /// admin branch of the rules ([asAdmin]); everyone else needs to be in
  /// the entry's `viewerIds`.
  PaginatedSource<AuditEntry> taskActivity(
    String taskId, {
    required bool asAdmin,
  });

  /// Every non-confidential entry of the organisation, newest first
  /// (verified admins only).
  PaginatedSource<AuditEntry> orgActivity();
}
