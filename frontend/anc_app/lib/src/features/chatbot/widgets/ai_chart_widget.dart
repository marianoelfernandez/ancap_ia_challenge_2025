import "dart:convert";
import "dart:math"; // Import dart:math for log and pow

import "package:flutter/material.dart";
import "package:fl_chart/fl_chart.dart";
import "package:anc_app/src/features/chatbot/services/chat_service.dart";
import "package:get_it/get_it.dart";

const Color _ancapYellow = Color(0xFFFFC107);
const Color _backgroundMid = Color(0xFF0B101A);

/// Enum for different chart types.
enum ChartType { bar, pie, line }

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
  final bool isDashboard;
  final String? naturalQuery;
  final String? sqlQuery;

  const AiDataResponseChart({
    super.key,
    required this.jsonString,
    this.isFullScreen = false, // Default to false
    this.isDashboard = false,
    this.naturalQuery,
    this.sqlQuery,
  });

  @override
  State<AiDataResponseChart> createState() => _AiDataResponseChartState();
}

class _AiDataResponseChartState extends State<AiDataResponseChart> {
  /// Holds the processed data, mapping each category to its aggregated value.
  Map<String, double> _dataValues = {};

  /// The title for the chart, derived from the column names in the JSON.
  String _chartTitle = "Data";

  /// The current chart type to display.
  ChartType _chartType = ChartType.bar;

  /// A key to manage state changes and force re-renders when data updates.
  late final ValueKey _widgetKey;

  /// Loading state for chart metadata
  bool _isLoadingMetadata = false;

  /// Chat service instance
  final ChatService _chatService = GetIt.instance<ChatService>();

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
  void _processData() async {
    try {
      debugPrint("Processing JSON: ${widget.jsonString}");
      // Transforms single cuotes into double quotes for valid JSON parsing
      String parsedString =
          widget.jsonString.replaceAll("'", '"').replaceAll("None", "null");

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

      if (widget.naturalQuery != null && widget.sqlQuery != null) {
        await _fetchChartMetadata(
          fallbackTitle: chartTitle,
          naturalQuery: widget.naturalQuery!,
          sqlQuery: widget.sqlQuery!,
          dataOutput: parsedString,
        );
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

  Future<void> _fetchChartMetadata({
    required String fallbackTitle,
    required String naturalQuery,
    required String sqlQuery,
    required String dataOutput,
  }) async {
    setState(() {
      _isLoadingMetadata = true;
    });
    try {
      final metadata = await _chatService.fetchChartMetadata(
        naturalQuery: naturalQuery,
        sqlQuery: sqlQuery,
        dataOutput: dataOutput,
      );
      
      debugPrint("Chart metadata: $metadata");
      final String title = metadata["title"] ?? fallbackTitle;
      final String chartTypeStr = metadata["chart"] ?? "Barras";

      ChartType defaultChartType = ChartType.bar;
      final lowerChartType = chartTypeStr.toLowerCase();
      if (lowerChartType == "piechart") {
        defaultChartType = ChartType.pie;
      } else if (lowerChartType == "linea" || lowerChartType == "línea") {
        defaultChartType = ChartType.line;
      }

      if (mounted) {
        setState(() {
          _chartTitle = title;
          _chartType = defaultChartType;
        });
      }
    } catch (e) {
      debugPrint("Error fetching chart metadata: $e");
    } finally {
      setState(() {
        _isLoadingMetadata = false;
      });
    }
  }

  void _cycleChartType() {
    setState(() {
      if (_chartType == ChartType.bar) {
        _chartType = ChartType.pie;
      } else if (_chartType == ChartType.pie) {
        // Only show line chart if there are multiple data points
        if (_dataValues.length > 1) {
          _chartType = ChartType.line;
        } else {
          _chartType = ChartType.bar;
        }
      } else {
        _chartType = ChartType.bar;
      }
    });
  }

  IconData _getChartTypeIcon(ChartType type) {
    switch (type) {
      case ChartType.bar:
        return Icons.bar_chart_outlined;
      case ChartType.pie:
        return Icons.pie_chart_outline;
      case ChartType.line:
        return Icons.show_chart_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the height based on the context (dashboard, full screen, or chat)
    double? chartHeight;
    if (!widget.isFullScreen && !widget.isDashboard) {
      chartHeight = 450; // Fixed height for chat view
    }
    // For full screen and dashboard, height is null so it can be expansive.

    return GestureDetector(
      onTap: widget.isFullScreen
          ? null // Disable tap if already full screen
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _FullScreenChartPage(
                    jsonString: widget.jsonString,
                    naturalQuery: widget.naturalQuery,
                    sqlQuery: widget.sqlQuery,
                  ),
                ),
              );
            },
      child: KeyedSubtree(
        key: _widgetKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            // Use SizedBox to control initial height, or allow it to be flexible
            height: chartHeight,
            child: _dataValues.isEmpty
                ? _buildPlaceholder()
                : _buildChartContainer(),
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

  Widget _buildChartContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          alignment: Alignment.center,
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
            if (_dataValues.isNotEmpty)
              Positioned(
                right: 0,
                child: IconButton(
                  icon: Icon(
                    _getChartTypeIcon(_chartType),
                    color: Colors.white70,
                  ),
                  onPressed: _cycleChartType,
                  tooltip: "Cambiar tipo de gráfico",
                ),
              ),
          ],
        ),
        SizedBox(height: widget.isFullScreen ? 24 : 16),
        Expanded(
          child: _isLoadingMetadata ? _buildLoadingAnimation() : _buildChart(),
        ),
      ],
    );
  }

  Widget _buildLoadingAnimation() {
    return Stack(
      children: [
        // Show the chart with reduced opacity
        Opacity(
          opacity: 0.3,
          child: _buildChart(),
        ),
        // Overlay loading animation
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: (0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_ancapYellow),
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  "Generando gráficos...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the main chart widget based on the current chart type.
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

    switch (_chartType) {
      case ChartType.pie:
        return _buildPieChart();
      case ChartType.line:
        if (useLogScale) {
          return _buildLogarithmicLineChart(
            labels,
            minOriginalVal,
            maxOriginalVal,
          );
        }
        return _buildLinearLineChart(labels, minOriginalVal, maxOriginalVal);
      case ChartType.bar:
      default:
        if (useLogScale) {
          return _buildLogarithmicChart(labels, minOriginalVal, maxOriginalVal);
        }
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

    return BarChart(
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
    );
  }

  /// Builds a linear scale chart
  Widget _buildLinearChart(List<String> labels, double minVal, double maxVal) {
    // Generate linear grid values
    final gridValues = _generateLinearGridValues(minVal, maxVal);

    double chartMaxY = gridValues.isNotEmpty ? gridValues.last : maxVal * 1.2;
    double interval = _calculateLinearInterval(maxVal);

    return BarChart(
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
    );
  }

  Widget _buildPieChart() {
    final List<String> labels = _dataValues.keys.toList();
    final total = _dataValues.values.fold(0.0, (sum, item) => sum + item);

    final List<Color> colors = List.generate(
      labels.length,
      (index) => Colors.primaries[index % Colors.primaries.length].shade300,
    );

    final List<PieChartSectionData> sections =
        List.generate(labels.length, (i) {
      final category = labels[i];
      final value = _dataValues[category]!;
      final percentage = total > 0 ? (value / total) * 100 : 0;

      return PieChartSectionData(
        color: colors[i],
        value: value,
        title: percentage > 5 ? "${percentage.toStringAsFixed(1)}%" : "",
        radius: widget.isFullScreen ? 120 : 80,
        titleStyle: TextStyle(
          fontSize: widget.isFullScreen ? 16 : 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
        ),
      );
    });

    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Can be implemented later for interactivity
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: widget.isFullScreen ? 60 : 40,
              sections: sections,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: _buildPieChartLegend(labels, colors),
        ),
      ],
    );
  }

  Widget _buildPieChartLegend(List<String> labels, List<Color> colors) {
    return ListView.builder(
      itemCount: labels.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Row(
            children: [
              Container(width: 16, height: 16, color: colors[index]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  labels[index],
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a linear scale line chart
  Widget _buildLinearLineChart(
    List<String> labels,
    double minVal,
    double maxVal,
  ) {
    final gridValues = _generateLinearGridValues(minVal, maxVal);
    double chartMaxY = gridValues.isNotEmpty ? gridValues.last : maxVal * 1.2;
    double interval = _calculateLinearInterval(maxVal);

    final spots = List.generate(labels.length, (index) {
      return FlSpot(index.toDouble(), _dataValues[labels[index]]!);
    });

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: chartMaxY,
        gridData: _buildGridData(gridValues, interval),
        titlesData: _buildLinearTitlesData(labels, gridValues),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final category = labels[spot.x.toInt()];
                final value = spot.y;
                return LineTooltipItem(
                  "$category\n",
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: _formatValue(value),
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _ancapYellow,
            barWidth: widget.isFullScreen ? 4 : 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: _ancapYellow.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a logarithmic scale line chart
  Widget _buildLogarithmicLineChart(
    List<String> labels,
    double minVal,
    double maxVal,
  ) {
    final gridValues = _generateLogGridValues(minVal, maxVal);
    double minY = log10(max(1.0, minVal));
    double maxY = log10(max(1.0, maxVal * 1.2));
    if (maxY - minY < 1) {
      maxY = minY + 2;
    }

    final spots = List.generate(labels.length, (index) {
      final originalVal = _dataValues[labels[index]]!;
      return FlSpot(index.toDouble(), log10(max(1.0, originalVal)));
    });

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: _buildGridData(gridValues, null),
        titlesData: _buildLogTitlesData(labels, gridValues),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final category = labels[spot.x.toInt()];
                final originalValue = _dataValues[category] ?? 0.0;
                return LineTooltipItem(
                  "$category\n",
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: _formatValue(originalValue),
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _ancapYellow,
            barWidth: widget.isFullScreen ? 4 : 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: _ancapYellow.withOpacity(0.3),
            ),
          ),
        ],
      ),
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
  final String? naturalQuery;
  final String? sqlQuery;

  const _FullScreenChartPage({
    required this.jsonString,
    this.naturalQuery,
    this.sqlQuery,
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
            naturalQuery: naturalQuery,
            sqlQuery: sqlQuery,
            isFullScreen: true, // Indicate that it's in full screen
          ),
        ),
      ),
    );
  }
}
