import "package:anc_app/src/features/dashboard/services/charts_service.dart";
import "package:anc_app/src/models/chart.dart";
import "package:anc_app/src/models/errors/charts_error.dart";
import "package:anc_app/src/models/query.dart";
import "package:flutter/foundation.dart";
import "package:oxidized/oxidized.dart";
import "package:pocketbase/pocketbase.dart";

class PocketbaseChartsService implements ChartsService {
  final PocketBase _pb;
  static const String _collectionName = "charts";

  PocketbaseChartsService(this._pb);

  @override
  Future<Result<Chart, ChartsError>> getChartById(String id) async {
    try {
      final record = await _pb.collection(_collectionName).getOne(id);
      final json = record.toJson();
      return Result.ok(
        Chart(
          id: json["id"],
          title: json["title"],
          chartData: json["chart_data"],
          userId: json["user"],
          created: json["created"],
          updated: json["updated"],
        ),
      );
    } catch (e) {
      debugPrint("Error getting chart by ID: $e");
      if (e is ClientException && e.statusCode == 404) {
        return Result.err(const ChartsErrorNotFound());
      }
      return Result.err(const ChartsErrorUnknown());
    }
  }

  @override
  Future<Result<List<Chart>, ChartsError>> getCharts({
    required int page,
    required int perPage,
    String? userId,
  }) async {
    try {
      String filter = "";
      if (userId != null) {
        filter = "user = '$userId'";
      }

      final result = await _pb.collection(_collectionName).getList(
            page: page,
            perPage: perPage,
            filter: filter.isNotEmpty ? filter : null,
            sort: "-created", // Most recent first
          );

      debugPrint("Retrieved ${result.items.length} charts from PocketBase");

      // Convert PocketBase records to Chart objects
      final charts = result.items.map((item) {
        final json = item.toJson();
        return Chart(
          id: json["id"],
          title: json["title"],
          chartData: json["chart_data"],
          userId: json["user"],
          created: json["created"],
          updated: json["updated"],
        );
      }).toList();

      return Result.ok(charts);
    } catch (e) {
      debugPrint("Error getting charts: $e");
      return Result.err(const ChartsErrorUnknown());
    }
  }

  @override
  Future<Result<Chart, ChartsError>> createChartFromQuery({
    required Query query,
    required String title,
    String? description,
  }) async {
    try {
      // Extract JSON chart data from the query's output or aiResponse
      String chartData = "";

      // First check if output contains chart data
      if (_isChartData(query.output)) {
        chartData = _extractChartData(query.output);
      }
      // Then check aiResponse if output didn't have chart data
      else if (_isChartData(query.aiResponse)) {
        chartData = _extractChartData(query.aiResponse);
      }

      // If no chart data was found, return error
      if (chartData.isEmpty) {
        return Result.err(
          const ChartsErrorInvalidData("No chart data found in query"),
        );
      }

      // Get the current user ID for the user field
      final currentUser = _pb.authStore.record;
      if (currentUser == null) {
        return Result.err(const ChartsErrorUnauthorized());
      }

      final userId = currentUser.id;

      final body = {
        "chart_data": chartData,
        "user": userId,
        "title": title,
        "description": description,
      };

      final record = await _pb.collection(_collectionName).create(body: body);
      final json = record.toJson();
      return Result.ok(
        Chart(
          id: json["id"],
          title: json["title"],
          chartData: json["chart_data"],
          userId: json["user"],
          created: json["created"],
          updated: json["updated"],
        ),
      );
    } catch (e) {
      debugPrint("Error creating chart from query: $e");
      return Result.err(const ChartsErrorUnknown());
    }
  }

  @override
  Future<Result<Chart, ChartsError>> updateChart({
    required String id,
    String? title,
    String? description,
    String? chartData,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (title != null) body["title"] = title;
      if (description != null) body["description"] = description;
      if (chartData != null) body["chart_data"] = chartData;

      if (body.isEmpty) {
        // No fields to update, return the current chart
        return getChartById(id);
      }

      final record =
          await _pb.collection(_collectionName).update(id, body: body);
      final json = record.toJson();
      return Result.ok(
        Chart(
          id: json["id"],
          title: json["title"],
          chartData: json["chart_data"],
          userId: json["user"],
          created: json["created"],
          updated: json["updated"],
        ),
      );
    } catch (e) {
      debugPrint("Error updating chart: $e");
      if (e is ClientException && e.statusCode == 404) {
        return Result.err(const ChartsErrorNotFound());
      }
      return Result.err(const ChartsErrorUnknown());
    }
  }

  @override
  Future<Result<Chart, ChartsError>> createChart({
    required String title,
    required String chartData,
    String? description,
  }) async {
    try {
      final currentUser = _pb.authStore.record;
      if (currentUser == null) {
        return Result.err(const ChartsErrorUnauthorized());
      }

      final userId = currentUser.id;

      final body = {
        "chart_data": chartData,
        "user": userId,
        "title": title,
        "description": description,
      };

      final record = await _pb.collection(_collectionName).create(body: body);
      final json = record.toJson();
      return Result.ok(
        Chart(
          id: json["id"],
          title: json["title"],
          chartData: json["chart_data"],
          userId: json["user"],
          created: json["created"],
          updated: json["updated"],
        ),
      );
    } catch (e) {
      debugPrint("Error creating chart: $e");
      return Result.err(const ChartsErrorUnknown());
    }
  }

  @override
  Future<Result<void, ChartsError>> deleteChart(String id) async {
    try {
      await _pb.collection(_collectionName).delete(id);
      return const Result.ok(null);
    } catch (e) {
      debugPrint("Error deleting chart: $e");
      if (e is ClientException && e.statusCode == 404) {
        return Result.err(const ChartsErrorNotFound());
      }
      return Result.err(const ChartsErrorUnknown());
    }
  }

  /// Checks if a text is chart data (starts with '{' and ends with '}')
  bool _isChartData(String text) {
    return text.trim().startsWith("{") && text.trim().endsWith("}");
  }

  /// Extracts chart data from text
  String _extractChartData(String text) {
    final trimmedText = text.trim();
    return trimmedText.substring(
      trimmedText.indexOf("{"),
      trimmedText.lastIndexOf("}") + 1,
    );
  }
}
