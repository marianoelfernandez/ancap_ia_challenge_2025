sealed class AuthError extends Error {
  final String message;

  AuthError(this.message);

  @override
  String toString() {
    return "AuthError: $message";
  }
}

final class AuthErrorUnknown extends AuthError {
  AuthErrorUnknown() : super("Unknown error");
}

final class AuthErrorEmailAlreadyInUse extends AuthError {
  AuthErrorEmailAlreadyInUse() : super("Email already in use");
}

final class AuthErrorInvalidCredentials extends AuthError {
  AuthErrorInvalidCredentials() : super("Invalid credentials");
}

