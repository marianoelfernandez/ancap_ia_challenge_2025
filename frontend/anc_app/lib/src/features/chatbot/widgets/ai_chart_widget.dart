import "dart:convert";
import "dart:math"; // Import dart:math for log

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

      String? categoryKey;
      String? valueKey;

      for (var col in columns) {
        if (col["name"] != null) {
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
          "No suitable category column found in JSON.",
        );
      }

      final bool isCountingOccurrences = (valueKey == null);

      final Map<String, double> aggregatedValues = {};
      String chartTitle = "Distribution of ${categoryKey.toLowerCase()}";

      for (var record in records) {
        final String categoryValue =
            record[categoryKey]?.toString().trim() ?? "Unknown";

        if (isCountingOccurrences) {
          aggregatedValues[categoryValue] =
              (aggregatedValues[categoryValue] ?? 0.0) + 1.0;
        } else {
          final dynamic rawValue = record[valueKey];
          double numericValue = 0.0;
          if (rawValue != null) {
            try {
              numericValue = double.parse(rawValue.toString());
            } catch (e) {
              debugPrint(
                "Warning: Could not parse '$rawValue' as double for key '$valueKey'. Defaulting to 0. Error: $e",
              );
            }
          }
          aggregatedValues[categoryValue] =
              (aggregatedValues[categoryValue] ?? 0.0) + numericValue;
        }
      }

      if (!isCountingOccurrences && valueKey != null) {
        chartTitle =
            "Total ${valueKey.toLowerCase().replaceAll('total', '')} by ${categoryKey.toLowerCase()}";
      }

      if (mounted) {
        setState(() {
          _dataValues = aggregatedValues;
          _chartTitle = chartTitle;
        });
      }
    } catch (e) {
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
            child: _dataValues.isEmpty ? _buildPlaceholder() : _buildChart(),
          ),
        ),
      ),
    );
  }

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
              _chartTitle,
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
    final List<String> labels = _dataValues.keys.toList();

    // Get the maximum original value for the chart's reference
    final double maxOriginalVal = _dataValues.values
        .fold(0.0, (prev, element) => element > prev ? element : prev);

    // If all values are 0 or less, we can't use log scale meaningfully.
    // Revert to linear or show placeholder.
    if (maxOriginalVal <= 1) {
      // Changed to 1, as log(1) = 0. We need values > 0 for log.
      return _buildLinearChart(); // Fallback to a linear chart or placeholder
    }

    // Transform values to log scale
    final Map<String, double> loggedDataValues = _dataValues.map((key, value) {
      // Use max(1.0, value) to prevent log(0) or log(negative) errors
      // log(1) = 0, so values 0-1 will be mapped to a small range near 0
      return MapEntry(key, log(max(1.0, value)));
    });

    // Calculate maxY based on logged values
    final double maxLoggedVal = loggedDataValues.values
        .fold(0.0, (prev, element) => element > prev ? element : prev);

    // Determine the "nice" unlogged values for Y-axis labels
    List<double> yAxisLabelValues = [];
    double currentPowerOfTen = 1.0;
    // Iterate until the label value exceeds the maximum original value
    while (currentPowerOfTen < maxOriginalVal * 1.5) {
      // Go a bit beyond max
      yAxisLabelValues.add(currentPowerOfTen);
      currentPowerOfTen *= 10;
      if (currentPowerOfTen == 0)
        break; // Avoid infinite loop if somehow currentPowerOfTen becomes 0
    }
    // Add intermediate values for better density if needed
    List<double> denseLabels = [];
    for (int i = 0; i < yAxisLabelValues.length - 1; i++) {
      denseLabels.add(yAxisLabelValues[i]);
      double nextVal = yAxisLabelValues[i + 1];
      // Add 2 and 5 times the current power of ten
      if (currentPowerOfTen / 10 * 2 < nextVal &&
          currentPowerOfTen / 10 * 2 < maxOriginalVal * 1.2) {
        denseLabels.add(yAxisLabelValues[i] * 2);
      }
      if (currentPowerOfTen / 10 * 5 < nextVal &&
          currentPowerOfTen / 10 * 5 < maxOriginalVal * 1.2) {
        denseLabels.add(yAxisLabelValues[i] * 5);
      }
    }
    if (yAxisLabelValues.isNotEmpty) denseLabels.add(yAxisLabelValues.last);
    yAxisLabelValues = denseLabels.toSet().toList()..sort();

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
                maxY: maxLoggedVal *
                    1.1, // Add some padding to the top on the logged scale
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final category = labels[group.x.toInt()];
                      // Display the original value in the tooltip
                      final originalValue = _dataValues[category] ?? 0.0;
                      return BarTooltipItem(
                        "$category\n",
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: formatValue(
                              originalValue,
                            ), // Use formatValue for tooltip
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
                      reservedSize: 60,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= labels.length) return Container();
                        final text = labels[index];
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4.0,
                          child: Transform.rotate(
                            angle: -0.7,
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
                        // Display original values on the Y-axis, but map to their logged positions
                        final unloggedValue = exp(
                          value,
                        ); // Convert back from logged value for display
                        // Check if this unlogged value is one of our "nice" labels or very close
                        bool isLabelPosition = yAxisLabelValues.any(
                          (labelVal) =>
                              (labelVal - unloggedValue).abs() <
                              (unloggedValue * 0.05),
                        ); // Tolerance
                        if (!isLabelPosition) return Container();

                        return Text(
                          formatValue(
                            unloggedValue,
                          ), // Format the original value
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
                  // Horizontal interval based on the logged values of yAxisLabelValues
                  horizontalInterval:
                      0.1, // Small interval as we draw specific lines
                  getDrawingHorizontalLine: (value) {
                    // Check if the current logged 'value' corresponds to one of our 'nice' unlogged labels
                    final double unloggedValue = exp(value);
                    bool shouldDraw = yAxisLabelValues.any(
                      (labelVal) =>
                          (labelVal - unloggedValue).abs() <
                          (unloggedValue * 0.05),
                    );

                    return FlLine(
                      color: shouldDraw
                          ? const Color(0xff37434d)
                          : Colors.transparent, // Draw only for "nice" labels
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: List.generate(_dataValues.length, (index) {
                  final originalVal = _dataValues[labels[index]]!;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY:
                            log(max(1.0, originalVal)), // Pass the logged value
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

  // Helper function to format large numbers with K, M, B suffixes
  String formatValue(double value) {
    if (value >= 1000000000) {
      return "${(value / 1000000000).toStringAsFixed(1)}B";
    } else if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}K";
    } else if (value % 1 == 0) {
      // If it's a whole number, display without decimal
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1); // Default to one decimal place for others
  }

  // Fallback linear chart for cases where log scale isn't suitable (e.g., all values <= 1)
  Widget _buildLinearChart() {
    final List<String> labels = _dataValues.keys.toList();
    final double maxVal = _dataValues.values
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
                maxY: maxVal * 1.2,
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
                            text: formatValue(rod.toY - 0),
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
                      reservedSize: 60,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= labels.length) return Container();
                        final text = labels[index];
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4.0,
                          child: Transform.rotate(
                            angle: -0.7,
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
                        if (value <= 0) return Container();
                        return Text(
                          formatValue(value),
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
                  horizontalInterval: maxVal / 5,
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
                        toY: _dataValues[labels[index]]!,
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
