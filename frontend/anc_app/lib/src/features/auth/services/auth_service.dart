import "package:anc_app/src/models/errors/auth_error.dart";
import "package:anc_app/src/models/user.dart";
import "package:oxidized/oxidized.dart";

abstract interface class AuthService {
  Future<Result<User, AuthError>> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<Result<User, AuthError>> signIn({
    required String email,
    required String password,
  });
  Future<Result<void, AuthError>> signOut();

  String? get token;
}
