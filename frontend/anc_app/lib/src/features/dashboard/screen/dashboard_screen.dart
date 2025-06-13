import "package:flutter/material.dart";
import "package:fl_chart/fl_chart.dart";
import "package:google_fonts/google_fonts.dart";
import "package:intl/intl.dart";
import "package:anc_app/src/features/sidebar/widgets/sidebar.dart";

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Colors
  static const Color _ancapYellow = Color(0xFFFFC107);
  static const Color _ancapDarkBlue = Color(0xFF002A53);

  // Background colors to match audit screen
  static const Color _backgroundStart = Color(0xFF060912);
  static const Color _backgroundMid = Color(0xFF0B101A);
  static const Color _backgroundEnd = Color(0xFF050505);

  final Color _foreground = Colors.white;
  final Color _mutedForeground = Colors.white.withValues(alpha: 0.7);
  final Color _border = Colors.white.withValues(alpha: 0.1);

  // Sample data for most consulted SQL queries
  final List<QueryData> _topQueries = [
    QueryData("SELECT * FROM sales", 120),
    QueryData("SELECT * FROM inventory", 85),
    QueryData("SELECT * FROM customers", 65),
    QueryData("SELECT * FROM orders", 45),
    QueryData("SELECT * FROM products", 30),
  ];

  // Sample data for query usage over time
  final List<TimeSeriesData> _queryTimeData = [
    TimeSeriesData(DateTime(2025, 6, 1), 45),
    TimeSeriesData(DateTime(2025, 6, 2), 60),
    TimeSeriesData(DateTime(2025, 6, 3), 35),
    TimeSeriesData(DateTime(2025, 6, 4), 70),
    TimeSeriesData(DateTime(2025, 6, 5), 85),
    TimeSeriesData(DateTime(2025, 6, 6), 75),
    TimeSeriesData(DateTime(2025, 6, 7), 90),
  ];

  // Sample data for query distribution by role
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
            // Sidebar
            const Sidebar(),

            // Main content
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _ancapYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _backgroundMid.withValues(alpha: 0.2),
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
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Dashboard",
                style: GoogleFonts.inter(
                  color: _foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top queries chart
                Expanded(
                  flex: 2,
                  child: _buildGlassEffectContainer(
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
                // Role distribution chart
                Expanded(
                  child: _buildGlassEffectContainer(
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
            // Stats cards
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassEffectContainer({
    required Widget child,
    EdgeInsets margin = EdgeInsets.zero,
    EdgeInsets padding = const EdgeInsets.all(24.0),
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
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
                // Truncate query text for display
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
              color: _ancapYellow.withOpacity(0.1),
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
    // Generate different colors for different roles
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

// Data models
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
