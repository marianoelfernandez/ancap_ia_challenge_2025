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
  /// Holds the processed data, mapping each category to its frequency.
  Map<String, int> _dataCounts = {};

  /// The title for the chart, derived from the column name in the JSON.
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

      if (columns.isEmpty || columns[0]["name"] == null) {
        throw const FormatException("Column name is missing.");
      }

      final String dataKey = columns[0]["name"];
      final String chartTitle = "Distribution of ${dataKey.toLowerCase()}";

      final Map<String, int> counts = {};
      for (var record in records) {
        final String value = record[dataKey]?.toString().trim() ?? "Unknown";
        counts[value] = (counts[value] ?? 0) + 1;
      }

      // Update the state with the new processed data
      if (mounted) {
        setState(() {
          _dataCounts = counts;
          _chartTitle = chartTitle;
        });
      }
    } catch (e) {
      // If parsing fails, clear the data and log the error.
      // A production app might show a user-friendly error message here.
      if (mounted) {
        setState(() {
          _dataCounts = {};
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
            child: _dataCounts.isEmpty ? _buildPlaceholder() : _buildChart(),
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
    final List<String> labels = _dataCounts.keys.toList();

    // Find the maximum frequency for the y-axis range
    final double maxFreq = _dataCounts.values
        .fold(0, (prev, element) => element > prev ? element.toDouble() : prev);

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
                maxY: maxFreq * 1.2, // Add some padding to the top
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
                            text: (rod.toY - 0).toStringAsFixed(0),
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
                        // Show integer values on the y-axis
                        if (value == 0 || value % 1 != 0) {
                          return Container();
                        }
                        return Text(
                          value.toInt().toString(),
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
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xff37434d),
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: List.generate(_dataCounts.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: _dataCounts[labels[index]]!.toDouble(),
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

/// An example screen to demonstrate the AiDataResponseChart widget.
class ChartExampleScreen extends StatelessWidget {
  const ChartExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Example JSON strings provided in the problem description
    const String singleDataJson =
        '{"status": "success", "data": {"data": [{"DPTONOM": "MONTEVIDEO "}], "columns": [{"name": "DPTONOM", "type": "STRING"}]}}';

    const String multiDataJson =
        '{"status": "success", "data": {"data": [{"CLINOM": "CLAVE CATALIZADOR X"}, {"CLINOM": "ESFUERZO NEXO PACÍFICO"}, {"CLINOM": "TRIUNFO GENERACIÓN CONSULTORES"}, {"CLINOM": "COMPLETA EXPLORADOR CONSULTORES"}, {"CLINOM": "CLAVE DESTACADO CONSULTORES"}, {"CLINOM": "ENTUSIASMO ESCALÓN INTERNACIONAL"}, {"CLINOM": "VANGUARDIA DISEÑO EMPRESAS"}, {"CLINOM": "OPTIMIZA SUPERIOR SOLUCIONES"}, {"CLINOM": "ESTÉRIL PRINCIPAL SELECTA"}, {"CLINOM": "CRISTALINA AVANZADO S.A."}, {"CLINOM": "UNIFICADA SUPERIOR CO."}, {"CLINOM": "BÚSQUEDA ESTUDIO S.A."}, {"CLINOM": "MAESTRA TECNO REGIONAL"}, {"CLINOM": "PILAR ALIANZA INC."}, {"CLINOM": "PURA FUNDICIÓN CORPORACIÓN"}, {"CLINOM": "REAL PORTAL LTDA."}, {"CLINOM": "RUMBO CRECIMIENTO CO."}, {"CLINOM": "NOBLEZA FRONTERIZO OBRAS"}, {"CLINOM": "ESENCIAL IMPULSO PACÍFICO"}, {"CLINOM": "ODISEA PRINCIPAL CORPORACIÓN"}], "columns": [{"name": "CLINOM", "type": "STRING"}]}}';

    // Example with duplicate data to show frequency counting
    const String duplicateDataJson =
        '{"status": "success", "data": {"data": [{"PRODUCT": "Laptop"}, {"PRODUCT": "Mouse"}, {"PRODUCT": "Laptop"}, {"PRODUCT": "Keyboard"}, {"PRODUCT": "Monitor"}, {"PRODUCT": "Laptop"}], "columns": [{"name": "PRODUCT", "type": "STRING"}]}}';

    return Scaffold(
      backgroundColor: const Color(0xff1f2e42),
      appBar: AppBar(
        title: const Text("AI Data Visualization"),
        backgroundColor: const Color(0xff2c4260),
      ),
      body: ListView(
        children: const [
          AiDataResponseChart(jsonString: multiDataJson),
          SizedBox(height: 20),
          AiDataResponseChart(jsonString: duplicateDataJson),
          SizedBox(height: 20),
          AiDataResponseChart(jsonString: singleDataJson),
        ],
      ),
    );
  }
}

// To run this example, ensure you have a main function and MaterialApp setup:
/*
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Chart Demo',
      home: ChartExampleScreen(),
    );
  }
}
*/
