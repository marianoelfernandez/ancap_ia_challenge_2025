import "dart:convert";

/// Model representing a conversation record from the API
class Conversation {
  final String id;
  final String collectionId;
  final String collectionName;
  final String conversation;
  final String userId;
  final DateTime created;

  Conversation({
    required this.id,
    required this.collectionId,
    required this.collectionName,
    required this.conversation,
    required this.userId,
    required this.created,
  });

  /// Creates a Conversation from JSON data
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json["id"],
      collectionId: json["collectionId"],
      collectionName: json["collectionName"],
      conversation: json["conversation"],
      userId: json["user_id"],
      created: DateTime.parse(json["created"]),
    );
  }

  /// Converts the Conversation to a JSON map
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "collectionId": collectionId,
      "collectionName": collectionName,
      "conversation": conversation,
      "user_id": userId,
      "created": created.toIso8601String(),
    };
  }
}

/// Model for paginated conversation response
class ConversationsResponse {
  final int page;
  final int perPage;
  final int totalPages;
  final int totalItems;
  final List<Conversation> items;

  ConversationsResponse({
    required this.page,
    required this.perPage,
    required this.totalPages,
    required this.totalItems,
    required this.items,
  });

  /// Creates a ConversationsResponse from JSON data
  factory ConversationsResponse.fromJson(Map<String, dynamic> json) {
    return ConversationsResponse(
      page: json["page"],
      perPage: json["perPage"],
      totalPages: json["totalPages"],
      totalItems: json["totalItems"],
      items: (json["items"] as List)
          .map((item) => Conversation.fromJson(item))
          .toList(),
    );
  }

  /// Converts the ConversationsResponse to a JSON map
  Map<String, dynamic> toJson() {
    return {
      "page": page,
      "perPage": perPage,
      "totalPages": totalPages,
      "totalItems": totalItems,
      "items": items.map((item) => item.toJson()).toList(),
    };
  }

  /// Creates a ConversationsResponse from a JSON string
  factory ConversationsResponse.fromRawJson(String str) =>
      ConversationsResponse.fromJson(json.decode(str));

  /// Converts the ConversationsResponse to a JSON string
  String toRawJson() => json.encode(toJson());
}
