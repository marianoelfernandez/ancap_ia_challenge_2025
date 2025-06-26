import "package:anc_app/src/models/chart.dart";
import "package:anc_app/src/models/errors/charts_error.dart";
import "package:anc_app/src/models/query.dart";
import "package:oxidized/oxidized.dart";

abstract interface class ChartsService {
  /// Get a specific chart by its ID
  Future<Result<Chart, ChartsError>> getChartById(String id);

  /// Get all charts for the current user
  Future<Result<List<Chart>, ChartsError>> getCharts({
    required int page,
    required int perPage,
    String? userId,
  });

  /// Create a new chart from a query
  Future<Result<Chart, ChartsError>> createChartFromQuery({
    required Query query,
    required String title,
    String? description,
  });

  /// Create a new chart directly from data
  Future<Result<Chart, ChartsError>> createChart({
    required String title,
    required String chartData,
    String? description,
  });

  /// Update an existing chart
  Future<Result<Chart, ChartsError>> updateChart({
    required String id,
    String? title,
    String? description,
    String? chartData,
  });

  /// Delete a chart
  Future<Result<void, ChartsError>> deleteChart(String id);
}
