
import "package:anc_app/src/models/errors/audit_error.dart";
import "package:oxidized/oxidized.dart";
import "package:anc_app/src/models/audit_record_list.dart";

abstract class AuditService {
  Future<Result<AuditRecordsResponse, AuditError>> getAuditRecords({
    required int page,
    required int perPage,
  });


}
