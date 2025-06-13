import "dart:convert";
import "package:http/http.dart" as http;
import "package:anc_app/src/env.dart";
import "package:anc_app/src/features/auth/services/auth_service.dart";
import "package:get_it/get_it.dart";

class ChatService {
  final AuthService _authService = GetIt.instance<AuthService>();
  final String _baseUrl = AppEnv.I.read(EnvKey.llmServiceUrl);

  Future<Map<String, dynamic>> sendMessage(
    String message, {
    String? conversationId,
  }) async {
    final token = _authService.token;
    if (token == null) {
      throw Exception("Not authenticated");
    }

    final response = await http.post(
      Uri.parse("$_baseUrl/query"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "query": message,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to send message: ${response.body}");
    }
  }
}
