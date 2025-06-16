import "package:anc_app/src/features/chatbot/services/conversation_service.dart";
import "package:anc_app/src/models/conversation.dart";
import "package:anc_app/src/models/errors/conversation_error.dart";
import "package:flutter/material.dart";
import "package:oxidized/oxidized.dart";
import "package:pocketbase/pocketbase.dart";

/// Pocketbase implementation of the ConversationService interface
class ConversationPocketbaseService implements ConversationService {
  final PocketBase _pb;
  final String _collectionName = "conversations";

  ConversationPocketbaseService(this._pb);

  @override
  Future<Result<ConversationsResponse, ConversationError>> getConversations({
    required int page,
    required int perPage,
    String? userId,
    required bool sortByCreationDateDesc,
  }) async {
    try {
      debugPrint(
        "ConversationService: Getting conversations with userId: $userId",
      );

      String? filterString;
      if (userId != null && userId.isNotEmpty) {
        filterString = "user_id = '$userId'";
        debugPrint("ConversationService: Using filter: $filterString");
      }

      final resultList = await _pb.collection(_collectionName).getList(
            page: page,
            perPage: perPage,
            filter: filterString,
            sort: sortByCreationDateDesc ? "-created" : null,
          );

      debugPrint(
        "ConversationService: Got ${resultList.items.length} conversations from PocketBase",
      );

      final response = ConversationsResponse(
        page: resultList.page,
        perPage: resultList.perPage,
        totalPages: resultList.totalPages,
        totalItems: resultList.totalItems,
        items: resultList.items
            .map((item) => Conversation.fromJson(item.toJson()))
            .toList(),
      );
      debugPrint(
        "ConversationService: Mapped to ${response.items.length} conversation models",
      );

      return Result.ok(response);
    } catch (e) {
      return Result.err(_handleError(e));
    }
  }

  @override
  Future<Result<Conversation, ConversationError>> getConversationById(
    String id,
  ) async {
    try {
      final record = await _pb.collection(_collectionName).getOne(id);
      return Result.ok(Conversation.fromJson(record.toJson()));
    } catch (e) {
      return Result.err(_handleError(e));
    }
  }

  @override
  Future<Result<Conversation, ConversationError>> createConversation(
    Map<String, dynamic> data,
  ) async {
    try {
      final record = await _pb.collection(_collectionName).create(body: data);
      return Result.ok(Conversation.fromJson(record.toJson()));
    } catch (e) {
      return Result.err(_handleError(e));
    }
  }

  @override
  Future<Result<Conversation, ConversationError>> updateConversation(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final record =
          await _pb.collection(_collectionName).update(id, body: data);
      return Result.ok(Conversation.fromJson(record.toJson()));
    } catch (e) {
      return Result.err(_handleError(e));
    }
  }

  @override
  Future<Result<bool, ConversationError>> deleteConversation(String id) async {
    try {
      await _pb.collection(_collectionName).delete(id);
      return const Result.ok(true);
    } catch (e) {
      return Result.err(_handleError(e));
    }
  }

  /// Handles errors from Pocketbase and converts them to ConversationError types
  ConversationError _handleError(dynamic error) {
    final errorMessage = error.toString();

    if (errorMessage.contains("404") || errorMessage.contains("not found")) {
      return ConversationNotFoundError(errorMessage);
    } else if (errorMessage.contains("400") ||
        errorMessage.contains("invalid") ||
        errorMessage.contains("validation")) {
      return ConversationInvalidDataError(errorMessage);
    } else if (errorMessage.contains("401") ||
        errorMessage.contains("403") ||
        errorMessage.contains("unauthorized") ||
        errorMessage.contains("forbidden")) {
      return ConversationUnauthorizedError(errorMessage);
    } else if (errorMessage.contains("500") ||
        errorMessage.contains("server error")) {
      return ConversationServerError(errorMessage);
    } else if (errorMessage.contains("Failed host lookup") ||
        errorMessage.contains("Connection refused") ||
        errorMessage.contains("Network is unreachable") ||
        errorMessage.contains("Connection timed out") ||
        errorMessage.contains("SocketException")) {
      return ConversationNetworkError(errorMessage);
    } else {
      return ConversationCustomError(errorMessage);
    }
  }
}
