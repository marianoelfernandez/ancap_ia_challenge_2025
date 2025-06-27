import "dart:convert";
import "dart:ui";

import "package:anc_app/src/features/chatbot/widgets/ai_chart_widget.dart";
import "package:anc_app/src/features/dashboard/cubits/dashboard_cubit.dart";
import "package:anc_app/src/features/dashboard/widgets/static_charts.dart";
import "package:anc_app/src/features/sidebar/widgets/sidebar.dart";
import "package:anc_app/src/features/sidebar/widgets/hamburger_menu_button.dart";
import "package:anc_app/src/models/chart.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:google_fonts/google_fonts.dart";

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardCubit _dashboardCubit;

  @override
  void initState() {
    super.initState();
    _dashboardCubit = DashboardCubit()..loadCharts();
  }

  @override
  void dispose() {
    _dashboardCubit.close();
    super.dispose();
  }

  static const Color _ancapYellow = Color(0xFFFFC107);
  static const Color _ancapDarkBlue = Color(0xFF002A53);

  static const Color _backgroundStart = Color(0xFF060912);
  static const Color _backgroundMid = Color(0xFF0B101A);
  static const Color _backgroundEnd = Color(0xFF050505);

  static const Color _foreground = Color(0xFFF8FAFC);
  static const Color _mutedForeground = Color(0xFF808EA2);

  final Color _glassBackground = Colors.white.withOpacity(0.03);
  static const Color _glassBorder = Color(0x1AFFFFFF);

  bool _isSidebarCollapsed = true; // Mobile menu closed by default

  bool get _isMobile => MediaQuery.of(context).size.width < 768;

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  void _closeSidebarOnNavigation() {
    if (_isMobile && !_isSidebarCollapsed) {
      setState(() {
        _isSidebarCollapsed = true;
      });
    }
  }

  Widget _buildAppBar() {
    return _buildGlassEffectContainer(
      margin: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 0,
      ),
      padding: const EdgeInsets.all(24.0),
      borderRadius: 8,
      child: Row(
        children: [
          _isMobile
              ? HamburgerMenuButton(
                  isOpen: !_isSidebarCollapsed,
                  onPressed: _toggleSidebar,
                  size: 24,
                )
              : Container(
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
                        color: _ancapYellow.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                      BoxShadow(
                        color: _ancapYellow.withOpacity(0.2),
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
          Expanded(
            child: Column(
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
                  "Una vista general de tus métricas clave.",
                  style: GoogleFonts.inter(
                    color: _mutedForeground,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
        child: _isMobile
            ? Stack(
                children: [
                  // Main content
                  Column(
                    children: [
                      _buildAppBar(),
                      Expanded(
                        child: _buildDashboardContent(),
                      ),
                    ],
                  ),
                  // Mobile sidebar overlay
                  if (!_isSidebarCollapsed)
                    Sidebar(
                      showChatFeatures: false,
                      isCollapsed: _isSidebarCollapsed,
                      onToggle: _toggleSidebar,
                    ),
                ],
              )
            : Row(
                children: [
                  // Desktop sidebar - always visible
                  const Sidebar(
                    showChatFeatures: false,
                    isCollapsed: false, // Always open on desktop
                  ),
                  // Main content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAppBar(),
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

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildAiGeneratedChartsSection(),
            const SizedBox(height: 32),
            _buildStaticChartsSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAiGeneratedChartsSection() {
    return BlocProvider.value(
      value: _dashboardCubit,
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Gráficos Guardados",
                style: GoogleFonts.inter(
                  color: _foreground,
                  fontSize: 20,
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

  Widget _buildStaticChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gráficas Estáticas",
          style: GoogleFonts.inter(
            color: _foreground,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        const StaticChartsWidget(),
      ],
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
    return _buildGlassEffectContainer(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              "Error al cargar los gráficos",
              style: GoogleFonts.inter(
                color: _foreground,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
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
    );
  }

  Widget _buildEmptyState() {
    return _buildGlassEffectContainer(
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
              "Interactúa con el chatbot para generar y guardar gráficos",
              style: GoogleFonts.inter(
                color: _mutedForeground,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsGrid(List<Chart> charts) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 500,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: charts.length,
      itemBuilder: (context, index) {
        final chart = charts[index];
        return _buildChartTile(chart);
      },
    );
  }

  Widget _buildChartTile(Chart chart) {
    String chartDataStr;
    if (chart.chartData is String) {
      chartDataStr = chart.chartData;
    } else if (chart.chartData is Map) {
      chartDataStr = jsonEncode(chart.chartData);
    } else {
      chartDataStr = "{}";
    }

    return _buildGlassEffectContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: _mutedForeground),
                  onPressed: () {
                    context.read<DashboardCubit>().deleteChart(chart.id);
                  },
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
      borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: _glassBackground,
            borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
            border: Border.all(color: _glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
