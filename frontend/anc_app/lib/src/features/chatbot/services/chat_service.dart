import "dart:convert";
import "package:flutter/widgets.dart";
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
        "conversation_id": conversationId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } else {
      throw Exception("Failed to send message: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> fetchChartMetadata({
    required String naturalQuery,
    required String sqlQuery,
    required String dataOutput,
  }) async {
    final token = _authService.token;
    if (token == null) {
      throw Exception("Not authenticated");
    }

    final response = await http.post(
      Uri.parse("$_baseUrl/chart"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "natural_query": naturalQuery,
        "data_output": dataOutput,
        "sql_query": sqlQuery,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } else {
      throw Exception("Failed to fetch chart metadata: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> executeSqlQuery(
    String sqlQuery, {
    String? conversationId,
  }) async {
    final token = _authService.token;
    if (token == null) {
      throw Exception("Not authenticated");
    }

    final response = await http.post(
      Uri.parse("$_baseUrl/query/sql"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "query": sqlQuery,
        "conversation_id": conversationId,
      }),
    );

    if (response.statusCode == 200) {
      debugPrint("SQL Response: ${response.body}");
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } else {
      throw Exception("Failed to execute SQL query: ${response.body}");
    }
  }
}
