/// Base class for all conversation-related errors
abstract class ConversationError implements Exception {
  final String message;

  ConversationError(this.message);

  @override
  String toString() => message;
}

/// Error thrown when a conversation is not found
class ConversationNotFoundError extends ConversationError {
  ConversationNotFoundError([String? message])
      : super(message ?? "Conversation not found");
}

/// Error thrown when invalid data is provided
class ConversationInvalidDataError extends ConversationError {
  ConversationInvalidDataError([String? message])
      : super(message ?? "Invalid conversation data provided");
}

/// Error thrown when user is not authorized
class ConversationUnauthorizedError extends ConversationError {
  ConversationUnauthorizedError([String? message])
      : super(message ?? "Unauthorized to access conversation");
}

/// Error thrown when a server error occurs
class ConversationServerError extends ConversationError {
  ConversationServerError([String? message])
      : super(message ?? "Server error occurred while processing conversation");
}

/// Error thrown when a network error occurs
class ConversationNetworkError extends ConversationError {
  ConversationNetworkError([String? message])
      : super(message ?? "Network error occurred while accessing conversation");
}

/// Error thrown for custom error cases
class ConversationCustomError extends ConversationError {
  ConversationCustomError(String message) : super(message);
}
