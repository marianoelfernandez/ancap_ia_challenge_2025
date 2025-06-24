import "dart:convert";
import "dart:math"; // Import dart:math for log and pow

import "package:flutter/material.dart";
import "package:fl_chart/fl_chart.dart";

const Color _ancapYellow = Color(0xFFFFC107);
const Color _backgroundMid = Color(0xFF0B101A);

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

  /// Builds the main BarChart widget with improved grid sizing.
  Widget _buildChart() {
    final List<String> labels = _dataValues.keys.toList();

    final double maxOriginalVal = _dataValues.values
        .fold(0.0, (prev, element) => element > prev ? element : prev);
    final double minOriginalVal = _dataValues.values.isEmpty
        ? 0.0
        : _dataValues.values.fold(
            double.infinity,
            (prev, element) => element < prev ? element : prev,
          );

    // Improved logarithmic scale detection
    bool useLogScale = _shouldUseLogScale(minOriginalVal, maxOriginalVal);

    if (useLogScale) {
      return _buildLogarithmicChart(labels, minOriginalVal, maxOriginalVal);
    } else {
      return _buildLinearChart(labels, minOriginalVal, maxOriginalVal);
    }
  }

  /// Determines if logarithmic scale should be used based on data characteristics
  bool _shouldUseLogScale(double minVal, double maxVal) {
    // Don't use log scale if we have non-positive values
    if (minVal <= 0) return false;

    // Don't use log scale if all values are the same
    if (maxVal == minVal) return false;

    // Use log scale if the ratio is large (indicating wide range)
    double ratio = maxVal / minVal;

    // Enhanced criteria for log scale:
    // 1. Large ratio (>100) suggests log scale benefits
    // 2. Max value is very large (>1M) and min is small (<1K)
    // 3. Data spans multiple orders of magnitude
    return ratio > 100 ||
        (maxVal > 1000000 && minVal < 1000) ||
        (log10(maxVal) - log10(minVal) > 3);
  }

  /// Builds a logarithmic scale chart
  Widget _buildLogarithmicChart(
    List<String> labels,
    double minVal,
    double maxVal,
  ) {
    // Generate logarithmic grid values
    final gridValues = _generateLogGridValues(minVal, maxVal);

    // Calculate chart bounds
    double minY = log10(max(1.0, minVal));
    double maxY = log10(max(1.0, maxVal * 1.2)); // Add 20% padding

    // Ensure we have at least some range
    if (maxY - minY < 1) {
      maxY = minY + 2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _chartTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.isFullScreen ? 20 : 16,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: widget.isFullScreen ? 24 : 16),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              minY: minY,
              maxY: maxY,
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
                          text: _formatValue(originalValue),
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
              titlesData: _buildLogTitlesData(labels, gridValues),
              borderData: FlBorderData(show: false),
              gridData: _buildGridData(gridValues, null),
              barGroups: List.generate(_dataValues.length, (index) {
                final originalVal = _dataValues[labels[index]]!;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: log10(max(1.0, originalVal)),
                      color: _ancapYellow,
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

  /// Builds a linear scale chart
  Widget _buildLinearChart(List<String> labels, double minVal, double maxVal) {
    // Generate linear grid values
    final gridValues = _generateLinearGridValues(minVal, maxVal);

    double chartMaxY = gridValues.isNotEmpty ? gridValues.last : maxVal * 1.2;
    double interval = _calculateLinearInterval(maxVal);

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
              minY: 0,
              maxY: chartMaxY,
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
                          text: _formatValue(rod.toY),
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
              titlesData: _buildLinearTitlesData(labels, gridValues),
              borderData: FlBorderData(show: false),
              gridData: _buildGridData(gridValues, interval),
              barGroups: List.generate(_dataValues.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: _dataValues[labels[index]]!,
                      color: _ancapYellow,
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

  /// Generates appropriate grid values for logarithmic scale
  List<double> _generateLogGridValues(double minVal, double maxVal) {
    List<double> values = [];

    // Start from the first power of 10 at or below minVal
    double startPower = (log10(max(1.0, minVal))).floorToDouble();
    double endPower = (log10(max(1.0, maxVal))).ceilToDouble() + 1;

    for (double power = startPower; power <= endPower; power++) {
      double baseValue = pow(10, power).toDouble();

      // Add major grid lines (powers of 10)
      if (baseValue >= minVal * 0.1 && baseValue <= maxVal * 2) {
        values.add(baseValue);
      }

      // Add intermediate values for better granularity
      if (power < endPower) {
        for (int multiplier in [2, 5]) {
          double intermediate = baseValue * multiplier;
          if (intermediate >= minVal * 0.1 && intermediate <= maxVal * 2) {
            values.add(intermediate);
          }
        }
      }
    }

    // Ensure minimum sensible values
    if (values.isEmpty || values.first > 1) {
      values.insert(0, 1.0);
    }

    return values.toSet().toList()..sort();
  }

  /// Generates appropriate grid values for linear scale
  List<double> _generateLinearGridValues(double minVal, double maxVal) {
    if (maxVal <= 0) return [0, 1, 2, 5, 10];

    double interval = _calculateLinearInterval(maxVal);
    List<double> values = [];

    double current = 0;
    while (current <= maxVal * 1.2) {
      values.add(current);
      current += interval;
    }

    return values;
  }

  /// Calculates an appropriate interval for linear scale
  double _calculateLinearInterval(double maxVal) {
    if (maxVal <= 0) return 1.0;

    // Target 5-8 grid lines
    double roughInterval = maxVal / 6;

    // Find the appropriate power of 10
    double power = pow(10, (log10(roughInterval)).floorToDouble()).toDouble();

    // Choose nice interval (1, 2, 5, or 10 times the power)
    if (roughInterval <= power) {
      return power;
    } else if (roughInterval <= power * 2) {
      return power * 2;
    } else if (roughInterval <= power * 5) {
      return power * 5;
    } else {
      return power * 10;
    }
  }

  /// Builds titles data for logarithmic chart
  FlTitlesData _buildLogTitlesData(
    List<String> labels,
    List<double> gridValues,
  ) {
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              child: Text(
                text.length > 15 ? "${text.substring(0, 16)}..." : text,
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: widget.isFullScreen ? 12 : 10,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: widget.isFullScreen ? 50 : 40,
          getTitlesWidget: (value, meta) {
            // Find corresponding original value for this log position
            double originalValue = pow(10, value).toDouble();

            // Only show labels for our predefined grid values
            bool shouldShow = gridValues
                .any((gridVal) => (log10(gridVal) - value).abs() < 0.01);

            if (!shouldShow) return Container();

            return Text(
              _formatValue(originalValue),
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: widget.isFullScreen ? 11 : 9,
              ),
              textAlign: TextAlign.right,
            );
          },
        ),
      ),
    );
  }

  /// Builds titles data for linear chart
  FlTitlesData _buildLinearTitlesData(
    List<String> labels,
    List<double> gridValues,
  ) {
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              child: Text(
                text.length > 15 ? "${text.substring(0, 16)}..." : text,
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: widget.isFullScreen ? 12 : 10,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: widget.isFullScreen ? 50 : 40,
          getTitlesWidget: (value, meta) {
            // Only show labels for our predefined grid values
            bool shouldShow =
                gridValues.any((gridVal) => (gridVal - value).abs() < 0.01);
            if (!shouldShow) return Container();

            return Text(
              _formatValue(value),
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: widget.isFullScreen ? 11 : 9,
              ),
              textAlign: TextAlign.right,
            );
          },
        ),
      ),
    );
  }

  /// Builds grid data for both logarithmic and linear charts
  FlGridData _buildGridData(List<double> gridValues, double? interval) {
    // Use 0.01 as default interval for logarithmic charts or when not provided
    final double gridInterval = interval ?? 0.01;

    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: gridInterval,
      getDrawingHorizontalLine: (value) {
        bool shouldDraw = gridValues.any((gridVal) {
          // For logarithmic scale, compare log values; for linear, compare direct values
          if (interval == null) {
            // Logarithmic mode (interval not provided)
            return (log10(gridVal) - value).abs() < 0.01;
          } else {
            // Linear mode (interval provided)
            return (gridVal - value).abs() < 0.01;
          }
        });

        return FlLine(
          color: shouldDraw ? const Color(0xff37434d) : Colors.transparent,
          strokeWidth: 1,
        );
      },
    );
  }

  /// Enhanced value formatting for wide range of values
  String _formatValue(double value) {
    if (value == 0) return "0";

    // Handle very small decimal values
    if (value.abs() < 1) {
      if (value.abs() >= 0.01) {
        return value.toStringAsFixed(2);
      } else if (value.abs() >= 0.001) {
        return value.toStringAsFixed(3);
      } else {
        // Use scientific notation for very small values
        return value.toStringAsExponential(1);
      }
    }

    // Handle large values with suffixes
    if (value.abs() >= 1000000000000) {
      return "${(value / 1000000000000).toStringAsFixed(1)}T";
    } else if (value.abs() >= 1000000000) {
      return "${(value / 1000000000).toStringAsFixed(1)}B";
    } else if (value.abs() >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    } else if (value.abs() >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}K";
    }

    // Handle medium values
    if (value % 1 == 0) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(1);
    }
  }

  /// Helper function for log base 10
  double log10(double value) => log(value) / ln10;
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
        foregroundColor: Colors.white,
        backgroundColor: _backgroundMid,
        elevation: 0,
      ),
      body: Container(
        color: _backgroundMid, // Match chart background
        child: Padding(
          padding: const EdgeInsets.all(8.0), // More padding in full screen
          child: AiDataResponseChart(
            jsonString: jsonString,
            isFullScreen: true, // Indicate that it's in full screen
          ),
        ),
      ),
    );
  }
}
