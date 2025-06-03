import "package:anc_app/src/features/auth/services/auth_service.dart";
import "package:anc_app/src/models/errors/auth_error.dart";
import "package:anc_app/src/models/user.dart";
import "package:flutter/material.dart";
import "package:oxidized/oxidized.dart";

class AuthServiceMock implements AuthService {
  final Map<String, User> _users = {};
  final Map<String, String> _passwords = {};

  @override
  Future<Result<User, AuthError>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = _users[email];
      if (user == null) {
        return Err(AuthErrorInvalidCredentials());
      }

      final userPassword = _passwords[email];
      if (userPassword != password) {
        return Err(AuthErrorInvalidCredentials());
      }

      return Ok(user);
    } catch (ex) {
      debugPrint("AuthServiceMock.signIn: $ex");
      return Err(AuthErrorUnknown());
    }
  }

  @override
  Future<Result<void, AuthError>> signOut() async {
    try {
      return const Ok(null);
    } catch (ex) {
      debugPrint("AuthServiceMock.signOut: $ex");
      return Err(AuthErrorUnknown());
    }
  }

  @override
  Future<Result<User, AuthError>> signUp({
    required String email,
    required String name,
    required String password,
  }) async {
    try {
      if (_users.containsKey(email)) {
        return Err(AuthErrorEmailAlreadyInUse());
      }

      final user = User(name: name, email: email);
      _users[email] = user;
      _passwords[email] = password;

      return Ok(user);
    } catch (ex) {
      debugPrint("AuthServiceMock.signUp: $ex");
      return Err(AuthErrorUnknown());
    }
  }
}
