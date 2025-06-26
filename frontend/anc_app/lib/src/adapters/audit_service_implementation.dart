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
      // 1. Fetch all conversations by iterating through pages
      List<Conversation> allConversations = [];
      int currentPage = 1;
      bool hasMorePages = true;

      while (hasMorePages) {
        final conversationsResult = await _conversationService.getConversations(
          page: currentPage,
          perPage: 100, // Fetch in chunks of 100
          sortByCreationDateDesc: true,
        );

        if (conversationsResult.isErr()) {
          final error = conversationsResult.unwrapErr();
          return Result.err(
            AuditError("Failed to get conversations: ${error.message}"),
          );
        }

        final response = conversationsResult.unwrap();
        allConversations.addAll(response.items);
        hasMorePages = response.page < response.totalPages;
        currentPage++;
      }

      // 2. Group conversations by user
      final Map<String, List<Conversation>> userConversations = {};
      for (final conversation in allConversations) {
        userConversations
            .putIfAbsent(conversation.userId, () => [])
            .add(conversation);
      }

      // 3. Create aggregated audit records for each user
      final List<AuditRecord> userAuditRecords = [];
      for (final entry in userConversations.entries) {
        final userId = entry.key;
        final conversations = entry.value;

        double totalCost = 0;
        final allQueriedTables = <String>{};
        DateTime lastActivity = conversations
            .map((c) => c.created)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        for (final conversation in conversations) {
          final queriesResult = await _queryService.getQueries(
            page: 1,
            perPage:
                100, // Assuming a conversation doesn't have more than 100 queries
            conversationId: conversation.id,
          );

          queriesResult.match(
            (queriesResponse) {
              totalCost += queriesResponse.items.fold<double>(
                0.0,
                (sum, query) => sum + query.cost,
              );
              for (final query in queriesResponse.items) {
                allQueriedTables.addAll(query.queriedTables);
              }
            },
            (error) {
              // Handle or log error for single conversation query fetch
            },
          );
        }

        final userResult = await _authService.getUserById(userId);
        final user = userResult.isOk() ? userResult.unwrap() : null;

        userAuditRecords.add(
          AuditRecord(
            username: userId,
            displayName: user?.name ?? "User ${userId.substring(0, 4)}",
            role: user?.role ?? "User",
            date: lastActivity,
            consultedTables: allQueriedTables.toList()..sort(),
            cost: totalCost,
          ),
        );
      }

      // Sort users by total cost descending
      userAuditRecords.sort((a, b) => b.cost.compareTo(a.cost));

      // 4. Paginate the aggregated results manually
      final totalItems = userAuditRecords.length;
      final totalPages = (totalItems / perPage).ceil();
      final startIndex = (page - 1) * perPage;
      final endIndex = (startIndex + perPage > totalItems)
          ? totalItems
          : startIndex + perPage;

      final paginatedItems = (startIndex < totalItems)
          ? userAuditRecords.sublist(startIndex, endIndex)
          : <AuditRecord>[];

      return Result.ok(
        AuditRecordsResponse(
          page: page,
          perPage: perPage,
          totalPages: totalPages,
          totalItems: totalItems,
          items: paginatedItems,
        ),
      );
    } catch (e) {
      return Result.err(AuditError("Unexpected error: $e"));
    }
  }
}
