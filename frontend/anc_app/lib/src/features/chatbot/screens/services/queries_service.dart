import "package:anc_app/src/models/errors/queries_error.dart";
import "package:anc_app/src/models/query.dart";
import "package:oxidized/oxidized.dart";

abstract interface class QueriesService {
  /// Fetch a paginated list of queries
  /// 
  /// [page] - The page number (1-based)
  /// [perPage] - Number of items per page
  /// [conversationId] - Optional filter by conversation ID
  Future<Result<QueriesResponse, QueriesError>> getQueries({
    required int page,
    required int perPage,
    String? conversationId,
  });
  
  /// Get a single query by ID
  Future<Result<Query, QueriesError>> getQueryById(String id);
  
  /// Create a new query
  Future<Result<Query, QueriesError>> createQuery({
    required String naturalQuery,
    required String sqlQuery,
    required String output,
    required double cost,
    required String conversationId,
  });
  
  /// Update an existing query
  Future<Result<Query, QueriesError>> updateQuery({
    required String id,
    String? naturalQuery,
    String? sqlQuery,
    String? output,
    double? cost,
    String? conversationId,
  });
  
  /// Delete a query
  Future<Result<void, QueriesError>> deleteQuery(String id);
}