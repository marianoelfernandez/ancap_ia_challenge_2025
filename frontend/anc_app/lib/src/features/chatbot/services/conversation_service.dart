import "package:anc_app/src/models/conversation.dart";
import "package:anc_app/src/models/errors/conversation_error.dart";
import "package:oxidized/oxidized.dart";

abstract class ConversationService {
  Future<Result<ConversationsResponse, ConversationError>> getConversations({
    required int page,
    required int perPage,
    String? userId,
    required bool sortByCreationDateDesc,
  });

  Future<Result<Conversation, ConversationError>> getConversationById(
    String id,
  );

  Future<Result<Conversation, ConversationError>> createConversation(
    Map<String, dynamic> data,
  );

  Future<Result<Conversation, ConversationError>> updateConversation(
    String id,
    Map<String, dynamic> data,
  );

  Future<Result<bool, ConversationError>> deleteConversation(
    String id,
  );
}
