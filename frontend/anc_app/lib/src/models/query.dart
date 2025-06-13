class Query {
  final String id;
  final String collectionId;
  final String collectionName;
  final String naturalQuery;
  final String sqlQuery;
  final String output;
  final double cost;
  final String conversationId;
  final DateTime created;
  final DateTime updated;

  Query({
    required this.id,
    required this.collectionId,
    required this.collectionName,
    required this.naturalQuery,
    required this.sqlQuery,
    required this.output,
    required this.cost,
    required this.conversationId,
    required this.created,
    required this.updated,
  });

  factory Query.fromJson(Map<String, dynamic> json) {
    return Query(
      id: json["id"],
      collectionId: json["collectionId"],
      collectionName: json["collectionName"],
      naturalQuery: json["natural_query"],
      sqlQuery: json["sql_query"],
      output: json["output"],
      cost: json["cost"] is int ? (json["cost"] as int).toDouble() : json["cost"],
      conversationId: json["conversation_id"],
      created: DateTime.parse(json["created"]),
      updated: DateTime.parse(json["updated"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "collectionId": collectionId,
      "collectionName": collectionName,
      "natural_query": naturalQuery,
      "sql_query": sqlQuery,
      "output": output,
      "cost": cost,
      "conversation_id": conversationId,
      "created": created.toIso8601String(),
      "updated": updated.toIso8601String(),
    };
  }
}

class QueriesResponse {
  final int page;
  final int perPage;
  final int totalPages;
  final int totalItems;
  final List<Query> items;

  QueriesResponse({
    required this.page,
    required this.perPage,
    required this.totalPages,
    required this.totalItems,
    required this.items,
  });

  factory QueriesResponse.fromJson(Map<String, dynamic> json) {
    return QueriesResponse(
      page: json["page"],
      perPage: json["perPage"],
      totalPages: json["totalPages"],
      totalItems: json["totalItems"],
      items: (json["items"] as List).map((item) => Query.fromJson(item)).toList(),
    );
  }
}
