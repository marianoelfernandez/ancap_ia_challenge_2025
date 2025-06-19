import "dart:convert";
import "dart:math"; // Import dart:math for log

import "package:flutter/material.dart";
import "package:fl_chart/fl_chart.dart";

final Color _glassBackground = Colors.white.withValues(alpha: 0.03);

/// A widget that parses a specific JSON structure from an AI response
/// and displays the categorical data as a bar chart.
///
/// This widget is designed to be robust, handling dynamic key names
/// (like 'DPTONOM' or 'CLINOM') and variable data lists.
class AiDataResponseChart extends StatefulWidget {
  /// The raw JSON string received from the AI service.
  final String jsonString;
  final bool
      isFullScreen; // New property to indicate if it's in full screen mode

  const AiDataResponseChart({
    super.key,
    required this.jsonString,
    this.isFullScreen = false, // Default to false
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
    // Determine the height based on whether it's full screen or not
    double chartHeight = widget.isFullScreen
        ? double.infinity
        : 450; // Smaller height when not full screen

    return GestureDetector(
      onTap: widget.isFullScreen
          ? null // Disable tap if already full screen
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      _FullScreenChartPage(jsonString: widget.jsonString),
                ),
              );
            },
      child: KeyedSubtree(
        key: _widgetKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            // Use SizedBox to control initial height
            height: chartHeight,
            child: _dataValues.isEmpty ? _buildPlaceholder() : _buildChart(),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      // Removed SizedBox height as parent SizedBox controls it
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_rounded, color: Colors.white70, size: 48),
          SizedBox(height: 16),
          Text(
            "No hay datos para mostrar", // Placeholder title simplified
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Por favor, vuelva a consultar el chat",
            style: TextStyle(color: Colors.white70),
          ),
        ],
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
      return _buildLinearChart(); // Fallback to a linear chart or placeholder
    }

    // Transform values to log scale
    final Map<String, double> loggedDataValues = _dataValues.map((key, value) {
      return MapEntry(key, log(max(1.0, value)));
    });

    // Calculate maxY based on logged values
    final double maxLoggedVal = loggedDataValues.values
        .fold(0.0, (prev, element) => element > prev ? element : prev);

    // Determine the "nice" unlogged values for Y-axis labels
    List<double> yAxisLabelValues = [];
    double currentPowerOfTen = 1.0;
    while (currentPowerOfTen < maxOriginalVal * 1.5) {
      yAxisLabelValues.add(currentPowerOfTen);
      currentPowerOfTen *= 10;
      if (currentPowerOfTen == 0) break;
    }

    List<double> denseLabels = [];
    for (int i = 0; i < yAxisLabelValues.length - 1; i++) {
      denseLabels.add(yAxisLabelValues[i]);
      double nextVal = yAxisLabelValues[i + 1];
      if (yAxisLabelValues[i] * 2 < nextVal &&
          yAxisLabelValues[i] * 2 < maxOriginalVal * 1.2) {
        denseLabels.add(yAxisLabelValues[i] * 2);
      }
      if (yAxisLabelValues[i] * 5 < nextVal &&
          yAxisLabelValues[i] * 5 < maxOriginalVal * 1.2) {
        denseLabels.add(yAxisLabelValues[i] * 5);
      }
    }
    if (yAxisLabelValues.isNotEmpty) denseLabels.add(yAxisLabelValues.last);
    yAxisLabelValues = denseLabels.toSet().toList()..sort();

    // NEW: Generate logged values for the labels
    final List<double> yAxisLabelLoggedValues =
        yAxisLabelValues.map((val) => log(max(1.0, val))).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _chartTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.isFullScreen ? 20 : 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: widget.isFullScreen ? 24 : 16),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxLoggedVal * 1.1,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final category = labels[group.x.toInt()];
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
                          text: formatValue(originalValue),
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
                    reservedSize: widget.isFullScreen ? 60 : 50,
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
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: widget.isFullScreen ? 12 : 10,
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
                    reservedSize: widget.isFullScreen ? 40 : 36,
                    getTitlesWidget: (value, meta) {
                      // Check if the current logged 'value' is close to one of our target logged label values
                      bool isLabelPosition = yAxisLabelLoggedValues.any(
                        (labelLoggedVal) =>
                            (labelLoggedVal - value).abs() < 0.01,
                      ); // Use a small absolute tolerance for logged values

                      if (!isLabelPosition) return Container();

                      // Find the original unlogged value corresponding to this logged value
                      // We need to iterate through yAxisLabelValues to find the correct label
                      double originalLabel = 0.0;
                      for (int i = 0; i < yAxisLabelValues.length; i++) {
                        if ((yAxisLabelLoggedValues[i] - value).abs() < 0.01) {
                          originalLabel = yAxisLabelValues[i];
                          break;
                        }
                      }
                      if (originalLabel == 0.0)
                        return Container(); // Should not happen if logic is correct

                      return Text(
                        formatValue(originalLabel), // Format the original value
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: widget.isFullScreen ? 12 : 10,
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
                // The horizontalInterval should be very small to ensure getDrawingHorizontalLine is called frequently
                horizontalInterval: 0.01, // Very small interval
                getDrawingHorizontalLine: (value) {
                  // Draw a line only if the current logged 'value' is very close to one of our target logged label values
                  bool shouldDraw = yAxisLabelLoggedValues.any(
                    (labelLoggedVal) => (labelLoggedVal - value).abs() < 0.01,
                  ); // Use a small absolute tolerance

                  return FlLine(
                    color: shouldDraw
                        ? const Color(0xff37434d)
                        : Colors.transparent,
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
                      toY: log(max(1.0, originalVal)),
                      color: Colors.tealAccent,
                      width: widget.isFullScreen ? 20 : 12,
                      borderRadius:
                          BorderRadius.circular(widget.isFullScreen ? 5 : 3),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
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
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  // Fallback linear chart for cases where log scale isn't suitable (e.g., all values <= 1)
  Widget _buildLinearChart() {
    final List<String> labels = _dataValues.keys.toList();
    final double maxVal = _dataValues.values
        .fold(0.0, (prev, element) => element > prev ? element : prev);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _chartTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.isFullScreen ? 20 : 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: widget.isFullScreen ? 24 : 16),
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
                    reservedSize: widget.isFullScreen ? 60 : 50,
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
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: widget.isFullScreen ? 12 : 10,
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
                    reservedSize: widget.isFullScreen ? 40 : 36,
                    getTitlesWidget: (value, meta) {
                      if (value <= 0) return Container();
                      return Text(
                        formatValue(value),
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: widget.isFullScreen ? 12 : 10,
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
                      width: widget.isFullScreen ? 20 : 12,
                      borderRadius:
                          BorderRadius.circular(widget.isFullScreen ? 5 : 3),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

/// A dedicated page to display the chart in full screen.
class _FullScreenChartPage extends StatelessWidget {
  final String jsonString;

  const _FullScreenChartPage({
    required this.jsonString,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Full Screen Chart"),
        backgroundColor: const Color(0xff2c4260),
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xff2c4260), // Match chart background
        child: Padding(
          padding: const EdgeInsets.all(16.0), // More padding in full screen
          child: AiDataResponseChart(
            jsonString: jsonString,
            isFullScreen: true, // Indicate that it's in full screen
          ),
        ),
      ),
    );
  }
}
