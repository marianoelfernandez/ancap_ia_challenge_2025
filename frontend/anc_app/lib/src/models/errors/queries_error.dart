sealed class QueriesError extends Error {
  final String message;

  QueriesError(this.message);

  @override
  String toString() {
    return "QueriesError: $message";
  }
}

final class QueriesErrorUnknown extends QueriesError {
  QueriesErrorUnknown() : super("Unknown error");
}

final class QueriesErrorNotFound extends QueriesError {
  QueriesErrorNotFound() : super("Query not found");
}

final class QueriesErrorInvalidData extends QueriesError {
  QueriesErrorInvalidData() : super("Invalid query data");
}

final class QueriesErrorServerError extends QueriesError {
  QueriesErrorServerError() : super("Server error");
}

final class QueriesErrorNetworkError extends QueriesError {
  QueriesErrorNetworkError() : super("Network error");
}

final class QueriesErrorUnauthorized extends QueriesError {
  QueriesErrorUnauthorized() : super("Unauthorized access");
}

final class QueriesErrorCustom extends QueriesError {
  QueriesErrorCustom(String message) : super(message);
}
