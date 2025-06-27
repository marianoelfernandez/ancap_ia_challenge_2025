sealed class AuthError extends Error {
  final String message;

  AuthError(this.message);

  @override
  String toString() {
    return "AuthError: $message";
  }
}

final class AuthErrorUnknown extends AuthError {
  AuthErrorUnknown() : super("Error desconocido");
}

final class AuthErrorEmailAlreadyInUse extends AuthError {
  AuthErrorEmailAlreadyInUse() : super("El correo electrónico ya está en uso");
}

final class AuthErrorInvalidCredentials extends AuthError {
  AuthErrorInvalidCredentials() : super("Credenciales inválidas");
}
