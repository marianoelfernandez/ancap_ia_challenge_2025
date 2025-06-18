import "dart:convert";
import "package:flutter/material.dart";
import "package:fl_chart/fl_chart.dart";

/// A widget that parses a specific JSON structure from an AI response
/// and displays the categorical data as a bar chart.
///
/// This widget is designed to be robust, handling dynamic key names
/// (like 'DPTONOM' or 'CLINOM') and variable data lists.
class AiDataResponseChart extends StatefulWidget {
  /// The raw JSON string received from the AI service.
  final String jsonString;

  const AiDataResponseChart({
    super.key,
    required this.jsonString,
  });

  @override
  State<AiDataResponseChart> createState() => _AiDataResponseChartState();
}

class _AiDataResponseChartState extends State<AiDataResponseChart> {
  /// Holds the processed data, mapping each category to its aggregated value.
  /// Changed to double to hold quantity values.
  Map<String, double> _dataValues = {};

  /// The title for the chart, derived from the column names in the JSON.
  String _chartTitle = "Data";

  /// A key to manage state changes and force re-renders when data updates.
  late final ValueKey _widgetKey;

  @override
  void initState() {
    super.initState();
    _widgetKey = ValueKey(widget.jsonString);
    _processData();
  }

  /// If the parent widget provides a new JSON string, re-process the data.
  @override
  void didUpdateWidget(covariant AiDataResponseChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.jsonString != oldWidget.jsonString) {
      _processData();
      // Update the key to ensure the widget tree rebuilds correctly
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _widgetKey = ValueKey(widget.jsonString);
          });
        }
      });
    }
  }

  /// Parses the JSON string and transforms it into a frequency map.
  void _processData() {
    try {
      debugPrint("Processing JSON: ${widget.jsonString}");
      // Transforms single cuotes into double quotes for valid JSON parsing
      String parsedString =
          widget.jsonString.replaceAll("'", '"').replaceAll("None", "null");

      debugPrint("Parsed JSON String: $parsedString");
      final decodedJson = jsonDecode(parsedString);
      debugPrint("Decoded JSON: $decodedJson");
      final dataPayload = decodedJson["data"];
      if (dataPayload == null ||
          dataPayload["data"] == null ||
          dataPayload["columns"] == null) {
        throw const FormatException(
          "Invalid JSON structure: 'data' or 'columns' missing.",
        );
      }

      final List<dynamic> records = dataPayload["data"];
      final List<dynamic> columns = dataPayload["columns"];

      // --- MODIFICATION START ---

      // Identify the category column (e.g., 'PLANOM' or 'DPTONOM')
      String? categoryKey;
      // Identify the value column (e.g., 'CantidadTotalVendida' or 'TotalEntregas')
      String? valueKey;

      for (var col in columns) {
        if (col["name"] != null) {
          // Heuristics to guess the category and value columns
          // Assuming the first string column is the category, and the first numeric is the value
          if (col["type"] == "STRING" && categoryKey == null) {
            categoryKey = col["name"];
          } else if ((col["type"] == "NUMERIC" || col["type"] == "INTEGER") &&
              valueKey == null) {
            valueKey = col["name"];
          }
        }
      }

      if (categoryKey == null) {
        throw const FormatException(
            "No suitable category column found in JSON.",);
      }
      // If there's no specific value column, default to counting occurrences (original behavior)
      final bool isCountingOccurrences = (valueKey == null);

      final Map<String, double> aggregatedValues = {};
      String chartTitle = "Distribution of ${categoryKey.toLowerCase()}";

      for (var record in records) {
        final String categoryValue =
            record[categoryKey]?.toString().trim() ?? "Unknown";

        if (isCountingOccurrences) {
          // Original logic: count occurrences if no numeric value column is found
          aggregatedValues[categoryValue] =
              (aggregatedValues[categoryValue] ?? 0.0) + 1.0;
        } else {
          // New logic: sum the numeric value
          final dynamic rawValue = record[valueKey!];
          double numericValue = 0.0;
          if (rawValue != null) {
            try {
              numericValue = double.parse(rawValue.toString());
            } catch (e) {
              debugPrint(
                  "Warning: Could not parse '$rawValue' as double for key '$valueKey'. Defaulting to 0. Error: $e",);
            }
          }
          aggregatedValues[categoryValue] =
              (aggregatedValues[categoryValue] ?? 0.0) + numericValue;
        }
      }

      // If we are summing values, update the chart title
      if (!isCountingOccurrences && valueKey != null) {
        chartTitle =
            "Total ${valueKey.toLowerCase().replaceAll('total', '')} by ${categoryKey.toLowerCase()}";
      }

      // --- MODIFICATION END ---

      // Update the state with the new processed data
      if (mounted) {
        setState(() {
          _dataValues =
              aggregatedValues; // Use _dataValues instead of _dataCounts
          _chartTitle = chartTitle;
        });
      }
    } catch (e) {
      // If parsing fails, clear the data and log the error.
      // A production app might show a user-friendly error message here.
      if (mounted) {
        setState(() {
          _dataValues = {};
          _chartTitle = "Error loading data";
        });
      }
      debugPrint("Error processing chart data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the ValueKey to ensure the widget rebuilds when data changes.
    return KeyedSubtree(
      key: _widgetKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: const Color(0xff2c4260),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: _dataValues.isEmpty
                ? _buildPlaceholder()
                : _buildChart(), // Use _dataValues
          ),
        ),
      ),
    );
  }

  /// Builds the placeholder to show when data is empty or loading.
  Widget _buildPlaceholder() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              _chartTitle, // Shows "Error loading data" on failure
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_chartTitle != "Error loading data")
              const Text(
                "No data to display.",
                style: TextStyle(color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the main BarChart widget.
  Widget _buildChart() {
    // Create a list of labels for the x-axis titles
    final List<String> labels = _dataValues.keys.toList(); // Use _dataValues

    // Find the maximum frequency for the y-axis range
    final double maxVal = _dataValues.values // Use _dataValues
        .fold(0.0, (prev, element) => element > prev ? element : prev);

    return AspectRatio(
      aspectRatio: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _chartTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2, // Add some padding to the top
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final category = labels[group.x.toInt()];
                      return BarTooltipItem(
                        "$category\n",
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: (rod.toY - 0)
                                .toStringAsFixed(0), // Format as integer
                            style: const TextStyle(
                              color: Colors.yellow,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60, // Space for labels
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= labels.length) return Container();
                        final text = labels[index];
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4.0,
                          child: Transform.rotate(
                            angle: -0.7, // Rotate labels to prevent overlap
                            child: Text(
                              text.length > 15
                                  ? "${text.substring(0, 12)}..."
                                  : text,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        // Show integer values on the y-axis, but also handle large numbers by abbreviating
                        if (value <= 0)
                          return Container(); // Don't show 0 or negative
                        String text = value.toInt().toString();
                        if (value >= 1000000000) {
                          text = "${(value / 1000000000).toStringAsFixed(1)}B";
                        } else if (value >= 1000000) {
                          text = "${(value / 1000000).toStringAsFixed(1)}M";
                        } else if (value >= 1000) {
                          text = "${(value / 1000).toStringAsFixed(1)}K";
                        }

                        return Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.left,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      maxVal / 5, // Dynamic intervals based on max value
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xff37434d),
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: List.generate(_dataValues.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: _dataValues[labels[index]]!, // Use _dataValues
                        color: Colors.tealAccent,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
