import "package:equatable/equatable.dart";

/// Base class for chart errors
abstract class ChartsError extends Equatable {
  const ChartsError();

  @override
  List<Object?> get props => [];
}

/// Error thrown when getting charts fails for unknown reasons
class ChartsErrorUnknown extends ChartsError {
  const ChartsErrorUnknown();

  @override
  String toString() => "Unknown charts error";
}

/// Error thrown when a chart is not found
class ChartsErrorNotFound extends ChartsError {
  const ChartsErrorNotFound();

  @override
  String toString() => "Chart not found";
}

/// Error thrown when creating or updating a chart fails
class ChartsErrorInvalidData extends ChartsError {
  final String message;
  const ChartsErrorInvalidData(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => "Invalid chart data: $message";
}

/// Error thrown when a user is not authorized to access a chart
class ChartsErrorUnauthorized extends ChartsError {
  const ChartsErrorUnauthorized();

  @override
  String toString() => "Unauthorized access to chart";
}
