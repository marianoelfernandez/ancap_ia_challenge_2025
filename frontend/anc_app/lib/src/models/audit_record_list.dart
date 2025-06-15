import "package:anc_app/src/models/audit_record.dart";

class AuditRecordsResponse {
  final int page;
  final int perPage;
  final int totalPages;
  final int totalItems;
  final List<AuditRecord> items;

  AuditRecordsResponse({
    required this.page,
    required this.perPage,
    required this.totalPages,
    required this.totalItems,
    required this.items,
  });
}
