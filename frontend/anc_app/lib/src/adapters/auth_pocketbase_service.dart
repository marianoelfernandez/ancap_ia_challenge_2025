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
  bool get isAuthenticated => pb.authStore.isValid;

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
        id: record.getStringValue("id"),
        email: record.getStringValue("email"),
        name: record.getStringValue("name"),
        role: record.getStringValue("role"),
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
      final authData =
          await pb.collection("users").authWithPassword(email, password);
      return Result.ok(
        User(
          id: authData.record.getStringValue("id"),
          email: authData.record.getStringValue("email"),
          name: authData.record.getStringValue("name"),
          role: authData.record.getStringValue("role"),
        ),
      );
    } catch (e, s) {
      debugPrint("signIn error: $e\n$s");
      return Result.err(AuthErrorUnknown());
    }
  }

  @override
  Future<Result<void, AuthError>> signOut() async {
    try {
      pb.authStore.clear();
      return const Result.ok(null);
    } catch (e) {
      return Result.err(AuthErrorUnknown());
    }
  }

  @override
  User? getCurrentUser() {
    if (!isAuthenticated) return null;

    try {
      final record = pb.authStore.record;
      if (record == null) return null;

      return User(
        id: record.getStringValue("id"),
        email: record.getStringValue("email"),
        name: record.getStringValue("name"),
        role: record.getStringValue("role"),
      );
    } catch (e) {
      debugPrint("Error getting current user: $e");
      return null;
    }
  }

  @override
  String? get token => pb.authStore.token;

  @override
  Future<Result<void, AuthError>> refreshToken() async {
    if (!isAuthenticated) return const Result.ok(null);

    try {
      await pb.collection("users").authRefresh();
      return const Result.ok(null);
    } catch (e) {
      return Result.err(AuthErrorUnknown());
    }
  }

  @override
  Future<Result<User, AuthError>> getUserById(String userId) async {
    try {
      final record = await pb.collection("users").getOne(userId);

      return Result.ok(
        User(
          id: record.getStringValue("id"),
          email: record.getStringValue("email"),
          name: record.getStringValue("name"),
          role: record.getStringValue("role"),
        ),
      );
    } catch (e) {
      debugPrint("Error getting user by ID: $e");
      return Result.err(AuthErrorUnknown());
    }
  }
}
