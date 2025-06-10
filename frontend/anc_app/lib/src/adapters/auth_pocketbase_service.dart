import "package:anc_app/src/features/auth/services/auth_service.dart";
import "package:anc_app/src/models/user.dart";
import "package:pocketbase/pocketbase.dart";
import "package:flutter/foundation.dart";
import "package:oxidized/oxidized.dart";
//auth error
import "package:anc_app/src/models/errors/auth_error.dart";

class AuthPocketBaseService implements AuthService {
  final PocketBase pb;

  AuthPocketBaseService({required PocketBase pocketBase}) : pb = pocketBase;

  @override
  Future<Result<User, AuthError>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final body = <String, dynamic>{
        "email": email,
        "password": password,
        "passwordConfirm": password,
        "name": name,
      };

      final record = await pb.collection("users").create(body: body);

      final user = User(
        email: record.getStringValue("email"),
        name: record.getStringValue("name"),
      );
      return Result.ok(user);
    } catch (e) {
      return Result.err(AuthErrorUnknown());
    }
  }

  @override
  Future<Result<User, AuthError>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await pb.collection("users").authWithPassword(email, password);
      return Result.ok(
        User(
          email: email,
          name: "",
        ),
      );
    } catch (e, s) {
      debugPrint("signIn error: $e\n$s");
      return Result.err(AuthErrorUnknown());
    }
  }

  @override
  Future<Result<User, AuthError>> signOut() async {
    try {
      pb.authStore.clear();
      return Result.ok(
        User(
          email: "",
          name: "",
        ),
      );
    } catch (e) {
      return Result.err(AuthErrorUnknown());
    }
  }
}
