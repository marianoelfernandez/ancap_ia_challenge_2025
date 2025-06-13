import "package:anc_app/src/features/chatbot/services/query_service.dart";
import "package:anc_app/src/models/errors/queries_error.dart";
import "package:anc_app/src/models/query.dart";
import "package:oxidized/oxidized.dart";
import "package:pocketbase/pocketbase.dart";

class QueryPocketbaseService implements QueryService {
  final PocketBase _pb;
  static const String _collectionName = "queries";

  QueryPocketbaseService(this._pb);

  @override
  Future<Result<QueriesResponse, QueriesError>> getQueries({
    required int page,
    required int perPage,
    String? conversationId,
  }) async {
    try {
      String filter = "";
      if (conversationId != null) {
        filter = "conversation_id = '$conversationId'";
      }

      final result = await _pb.collection(_collectionName).getList(
            page: page,
            perPage: perPage,
            filter: filter.isNotEmpty ? filter : null,
          );

      final response = QueriesResponse(
        page: result.page,
        perPage: result.perPage,
        totalPages: result.totalPages,
        totalItems: result.totalItems,
        items:
            result.items.map((item) => Query.fromJson(item.toJson())).toList(),
      );

      return Result.ok(response);
    } catch (e) {
      return Result.err(QueriesErrorUnknown());
    }
  }

  @override
  Future<Result<Query, QueriesError>> getQueryById(String id) async {
    try {
      final record = await _pb.collection(_collectionName).getOne(id);
      return Result.ok(Query.fromJson(record.toJson()));
    } catch (e) {
      return Result.err(QueriesErrorUnknown());
    }
  }

  @override
  Future<Result<Query, QueriesError>> createQuery({
    required String naturalQuery,
    required String sqlQuery,
    required String output,
    required double cost,
    required String conversationId,
  }) async {
    try {
      final body = {
        "natural_query": naturalQuery,
        "sql_query": sqlQuery,
        "output": output,
        "cost": cost,
        "conversation_id": conversationId,
      };

      final record = await _pb.collection(_collectionName).create(body: body);
      return Result.ok(Query.fromJson(record.toJson()));
    } catch (e) {
      return Result.err(QueriesErrorUnknown());
    }
  }

  @override
  Future<Result<Query, QueriesError>> updateQuery({
    required String id,
    String? naturalQuery,
    String? sqlQuery,
    String? output,
    double? cost,
    String? conversationId,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (naturalQuery != null) body["natural_query"] = naturalQuery;
      if (sqlQuery != null) body["sql_query"] = sqlQuery;
      if (output != null) body["output"] = output;
      if (cost != null) body["cost"] = cost;
      if (conversationId != null) body["conversation_id"] = conversationId;

      if (body.isEmpty) {
        // No fields to update, return the current record
        return getQueryById(id);
      }

      final record =
          await _pb.collection(_collectionName).update(id, body: body);
      return Result.ok(Query.fromJson(record.toJson()));
    } catch (e) {
      return Result.err(QueriesErrorUnknown());
    }
  }

  @override
  Future<Result<void, QueriesError>> deleteQuery(String id) async {
    try {
      await _pb.collection(_collectionName).delete(id);
      return const Result.ok(null);
    } catch (e) {
      return Result.err(QueriesErrorUnknown());
    }
  }
}
