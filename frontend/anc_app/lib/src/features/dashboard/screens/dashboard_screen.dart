import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:fl_chart/fl_chart.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:google_fonts/google_fonts.dart";
import "package:intl/intl.dart";

import "package:anc_app/src/features/chatbot/widgets/ai_chart_widget.dart";
import "package:anc_app/src/features/dashboard/cubits/dashboard_cubit.dart";
import "package:anc_app/src/features/sidebar/widgets/sidebar.dart";
import "package:anc_app/src/models/chart.dart";

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color _ancapYellow = Color(0xFFFFC107);
  static const Color _ancapDarkBlue = Color(0xFF002A53);

  static const Color _backgroundStart = Color(0xFF060912);
  static const Color _backgroundMid = Color(0xFF0B101A);
  static const Color _backgroundEnd = Color(0xFF050505);

  final Color _glassBackground = Colors.white.withValues(alpha: 0.03);
  static const Color _glassBorder = Color(0x1AFFFFFF);

  final Color _foreground = Colors.white;
  final Color _mutedForeground = Colors.white.withAlpha(179);
  final Color _border = Colors.white.withAlpha(25);

  final List<QueryData> _topQueries = [
    QueryData("SELECT * FROM sales", 120),
    QueryData("SELECT * FROM inventory", 85),
    QueryData("SELECT * FROM customers", 65),
    QueryData("SELECT * FROM orders", 45),
    QueryData("SELECT * FROM products", 30),
  ];

  final List<TimeSeriesData> _queryTimeData = [
    TimeSeriesData(DateTime(2025, 6, 1), 45),
    TimeSeriesData(DateTime(2025, 6, 2), 60),
    TimeSeriesData(DateTime(2025, 6, 3), 35),
    TimeSeriesData(DateTime(2025, 6, 4), 70),
    TimeSeriesData(DateTime(2025, 6, 5), 85),
    TimeSeriesData(DateTime(2025, 6, 6), 75),
    TimeSeriesData(DateTime(2025, 6, 7), 90),
  ];

  final Map<String, double> _queryByRole = {
    "Analyst": 45,
    "Manager": 25,
    "Admin": 15,
    "Developer": 10,
    "Guest": 5,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_backgroundStart, _backgroundMid, _backgroundEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            const Sidebar(showChatFeatures: false),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildDashboardContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return _buildGlassEffectContainer(
      margin: const EdgeInsets.only(left: 24, right: 24, top: 24),
      padding: const EdgeInsets.all(24.0),
      borderRadius: 8,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  _ancapYellow,
                  Color(0xFFF59E0B),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _ancapYellow.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: _ancapYellow.withValues(alpha: 0.2),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.dashboard_outlined,
              color: _ancapDarkBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Dashboard",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: _foreground,
                  fontSize: 18,
                ),
              ),
              Text(
                "Análisis de consultas SQL",
                style: GoogleFonts.inter(
                  color: _mutedForeground,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildGlassEffectContainer(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Consultas SQL más frecuentes",
                          style: GoogleFonts.inter(
                            color: _foreground,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: _buildBarChart(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildGlassEffectContainer(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Distribución por rol",
                          style: GoogleFonts.inter(
                            color: _foreground,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: _buildPieChart(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Time series chart
            _buildGlassEffectContainer(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tendencia de consultas en el tiempo",
                    style: GoogleFonts.inter(
                      color: _foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _buildLineChart(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.query_stats,
                    title: "Total de consultas",
                    value: "1,245",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people_outline,
                    title: "Usuarios activos",
                    value: "37",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.table_chart_outlined,
                    title: "Tablas consultadas",
                    value: "18",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.speed_outlined,
                    title: "Tiempo promedio",
                    value: "1.2s",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const SizedBox(height: 16),
            _buildAiGeneratedChartsSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAiGeneratedChartsSection() {
    return BlocProvider(
      create: (context) => DashboardCubit()..loadCharts(),
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Gráficos Guardados",
                style: GoogleFonts.inter(
                  color: _foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (state is DashboardLoading)
                _buildLoadingIndicator()
              else if (state is DashboardError)
                _buildErrorDisplay(state.error.toString())
              else if (state is DashboardLoaded)
                state.charts.isEmpty
                    ? _buildEmptyState()
                    : _buildChartsGrid(state.charts),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: _ancapYellow),
            const SizedBox(height: 16),
            Text(
              "Cargando gráficos...",
              style: GoogleFonts.inter(
                color: _mutedForeground,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDisplay(String errorMessage) {
    String displayMessage = errorMessage;
    String title = "Error al cargar los gráficos";
    bool is403 =
        errorMessage.contains("403") || errorMessage.contains("superusers");

    if (is403) {
      title = "Error de permisos";
      displayMessage =
          "No tienes permisos para acceder a los gráficos guardados. Contacta al administrador para configurar los permisos de PocketBase.";
    }

    return _buildGlassEffectContainer(
      padding: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                is403 ? Icons.lock_outline : Icons.error_outline,
                color: is403 ? Colors.orangeAccent : Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: _foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                displayMessage,
                style: GoogleFonts.inter(
                  color: _mutedForeground,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<DashboardCubit>().loadCharts(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ancapYellow,
                  foregroundColor: Colors.black,
                ),
                child: const Text("Reintentar"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return _buildGlassEffectContainer(
      padding: const  EdgeInsets.all(24.0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bar_chart_outlined,
                color: _ancapYellow,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                "No hay gráficos guardados",
                style: GoogleFonts.inter(
                  color: _foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Interactúa con el chatbot para generar gráficos",
                style: GoogleFonts.inter(
                  color: _mutedForeground,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartsGrid(List<Chart> charts) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: charts.length,
      itemBuilder: (context, index) {
        final chart = charts[index];
        return _buildChartTile(chart);
      },
    );
  }

  Widget _buildChartTile(Chart chart) {
    // Convert chartData to a string if it's not already one
    String chartDataStr;
    if (chart.chartData is String) {
      chartDataStr = chart.chartData;
    } else if (chart.chartData is Map) {
      chartDataStr = jsonEncode(chart.chartData);
    } else {
      debugPrint("Unexpected chartData type: ${chart.chartData.runtimeType}");
      chartDataStr = "{}"; // Empty chart as fallback
    }

    return _buildGlassEffectContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  chart.title,
                  style: GoogleFonts.inter(
                    color: _foreground,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                onPressed: () =>
                    context.read<DashboardCubit>().deleteChart(chart.id),
                iconSize: 20,
                splashRadius: 20,
                tooltip: "Eliminar gráfico",
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: AiDataResponseChart(
              jsonString: chartDataStr,
              isDashboard: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassEffectContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: _glassBackground,
            borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
            border: Border.all(color: _glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 150,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: _backgroundStart.withValues(alpha: 0.8),
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                "${_topQueries[groupIndex].query}\n${rod.toY.round()} veces",
                GoogleFonts.inter(
                  color: _foreground,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String text = _topQueries[value.toInt()].query;
                if (text.length > 15) {
                  text = "${text.substring(0, 12)}...";
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: GoogleFonts.inter(
                      color: _mutedForeground,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.inter(
                    color: _mutedForeground,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: _border,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
          getDrawingVerticalLine: (value) =>
              const FlLine(color: Colors.transparent),
        ),
        barGroups: _topQueries.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.count.toDouble(),
                color: _ancapYellow,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: _queryByRole.entries.map((entry) {
          final color = _getColorForRole(entry.key);
          return PieChartSectionData(
            color: color,
            value: entry.value,
            title: "${entry.value.toInt()}%",
            radius: 100,
            titleStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _foreground,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: _backgroundStart.withValues(alpha: 0.8),
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = _queryTimeData[spot.x.toInt()].date;
                final formattedDate = DateFormat("dd/MM").format(date);
                return LineTooltipItem(
                  "$formattedDate: ${spot.y.toInt()} consultas",
                  GoogleFonts.inter(
                    color: _foreground,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: _border,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= _queryTimeData.length || value < 0) {
                  return const SizedBox.shrink();
                }
                final date = _queryTimeData[value.toInt()].date;
                final formattedDate = DateFormat("dd/MM").format(date);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    formattedDate,
                    style: GoogleFonts.inter(
                      color: _mutedForeground,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.inter(
                    color: _mutedForeground,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: _queryTimeData.length - 1.0,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: _queryTimeData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
            }).toList(),
            isCurved: true,
            barWidth: 3,
            color: _ancapYellow,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: _ancapYellow,
                  strokeWidth: 2,
                  strokeColor: _foreground,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _ancapYellow.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return _buildGlassEffectContainer(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: _mutedForeground,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: _mutedForeground,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              color: _foreground,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForRole(String role) {
    switch (role) {
      case "Analyst":
        return _ancapYellow;
      case "Manager":
        return Colors.blue;
      case "Admin":
        return Colors.green;
      case "Developer":
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }
}

// Helper classes for dashboard data
class QueryData {
  final String query;
  final int count;

  QueryData(this.query, this.count);
}

class TimeSeriesData {
  final DateTime date;
  final int count;

  TimeSeriesData(this.date, this.count);
}
