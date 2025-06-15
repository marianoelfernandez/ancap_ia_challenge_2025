import "package:anc_app/src/features/audit/services/audit_service.dart";
import "package:anc_app/src/features/chatbot/services/conversation_service.dart";
import "package:anc_app/src/features/chatbot/services/query_service.dart";
import "package:anc_app/src/features/auth/services/auth_service.dart";
import "package:anc_app/src/models/audit_record.dart";
import "package:anc_app/src/models/audit_record_list.dart";
import "package:anc_app/src/models/conversation.dart";
import "package:anc_app/src/models/errors/audit_error.dart";
import "package:oxidized/oxidized.dart";

class AuditServiceImpl implements AuditService {
  final ConversationService _conversationService;
  final QueryService _queryService;
  final AuthService _authService;

  AuditServiceImpl(
    this._conversationService,
    this._queryService,
    this._authService,
  );

  @override
  Future<Result<AuditRecordsResponse, AuditError>> getAuditRecords({
    required int page,
    required int perPage,
  }) async {
    try {
      final conversationsResult = await _conversationService.getConversations(
        page: page,
        perPage: perPage,
        sortByCreationDateDesc: true,
      );

      return conversationsResult.match(
        (conversationsResponse) async {
          final auditRecords = <AuditRecord>[];

          for (final conversation in conversationsResponse.items) {
            final auditRecordResult =
                await _createAuditRecordFromConversation(conversation);

            auditRecordResult.match(
              (auditRecord) => auditRecords.add(auditRecord),
              (_) => {},
            );
          }

          return Result.ok(
            AuditRecordsResponse(
              page: conversationsResponse.page,
              perPage: conversationsResponse.perPage,
              totalPages: conversationsResponse.totalPages,
              totalItems: conversationsResponse.totalItems,
              items: auditRecords,
            ),
          );
        },
        (error) => Result.err(
          AuditError("Failed to get conversations: ${error.message}"),
        ),
      );
    } catch (e) {
      return Result.err(AuditError("Unexpected error: $e"));
    }
  }

  @override
  Future<Result<AuditRecord, AuditError>> getAuditRecordByConversationId(
    String conversationId,
  ) async {
    try {
      final conversationResult =
          await _conversationService.getConversationById(conversationId);

      return conversationResult.match(
        (conversation) => _createAuditRecordFromConversation(conversation),
        (error) => Result.err(
          AuditError("Failed to get conversation: ${error.message}"),
        ),
      );
    } catch (e) {
      return Result.err(AuditError("Unexpected error: $e"));
    }
  }

  Future<Result<AuditRecord, AuditError>> _createAuditRecordFromConversation(
    Conversation conversation,
  ) async {
    try {
      final queriesResult = await _queryService.getQueries(
        page: 1,
        perPage: 100,
        conversationId: conversation.id,
      );

      return queriesResult.match(
        (queriesResponse) {
          final totalCost = queriesResponse.items.fold<double>(
            0.0,
            (sum, query) => sum + query.cost,
          );

          final allQueriedTables = <String>{};
          for (final query in queriesResponse.items) {
            allQueriedTables.addAll(query.queriedTables);
          }

          return _authService.getUserById(conversation.userId).match(
            (user) {
              return Result.ok(
                AuditRecord(
                  username: conversation.userId,
                  displayName: user.name,
                  role: user.role,
                  date: conversation.created,
                  consultedTables: allQueriedTables.toList(),
                  cost: totalCost,
                ),
              );
            },
            (error) {
              String displayName =
                  "User ${conversation.userId.substring(0, 4)}";

              return Result.ok(
                AuditRecord(
                  username: conversation.userId,
                  displayName: displayName,
                  role: "User",
                  date: conversation.created,
                  consultedTables: allQueriedTables.toList(),
                  cost: totalCost,
                ),
              );
            },
          );
        },
        (error) =>
            Result.err(AuditError("Failed to get queries: ${error.message}")),
      );
    } catch (e) {
      return Result.err(AuditError("Unexpected error: $e"));
    }
  }
}
