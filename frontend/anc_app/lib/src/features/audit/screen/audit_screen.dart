import "dart:ui";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:google_fonts/google_fonts.dart";
import "package:anc_app/src/features/sidebar/widgets/sidebar.dart";
import "package:anc_app/src/features/audit/cubit/audit_cubit.dart";
import "package:intl/intl.dart";

const Color _ancapYellow = Color(0xFFFFC107);
const Color _ancapDarkBlue = Color(0xFF002A53);

const Color _backgroundStart = Color(0xFF060912);
const Color _backgroundMid = Color(0xFF0B101A);
const Color _backgroundEnd = Color(0xFF050505);

const Color _foreground = Color(0xFFF8FAFC);
const Color _mutedForeground = Color(0xFF808EA2);
const Color _border = Color(0xFF1A1F29);

final Color _glassBackground = Colors.white.withValues(alpha: 0.03);
const Color _glassBorder = Color(0x1AFFFFFF);

class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuditCubit()..fetchAuditRecords(),
      child: const _AuditScreenView(),
    );
  }
}

class _AuditScreenView extends StatefulWidget {
  const _AuditScreenView();

  @override
  State<_AuditScreenView> createState() => _AuditScreenViewState();
}

class _AuditScreenViewState extends State<_AuditScreenView> {
  final TextEditingController _usernameFilter = TextEditingController();
  final TextEditingController _roleFilter = TextEditingController();
  final TextEditingController _dateFilter = TextEditingController();
  final TextEditingController _tablesFilter = TextEditingController();
  final TextEditingController _costFilter = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameFilter.addListener(_applyFilters);
    _roleFilter.addListener(_applyFilters);
    _dateFilter.addListener(_applyFilters);
    _tablesFilter.addListener(_applyFilters);
    _costFilter.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _usernameFilter.dispose();
    _roleFilter.dispose();
    _dateFilter.dispose();
    _tablesFilter.dispose();
    _costFilter.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final cubit = context.read<AuditCubit>();
    cubit.applyFilters(
      usernameFilter: _usernameFilter.text,
      roleFilter: _roleFilter.text,
      dateFilter: _dateFilter.text,
      tablesFilter: _tablesFilter.text,
      costFilter: _costFilter.text,
    );
  }

  void _clearAllFilters() {
    _usernameFilter.clear();
    _roleFilter.clear();
    _dateFilter.clear();
    _tablesFilter.clear();
    _costFilter.clear();
    context.read<AuditCubit>().clearAllFilters();
  }

  void _addTableTag(String tag) {
    if (tag.isNotEmpty) {
      context.read<AuditCubit>().addTableTag(tag);
      _tablesFilter.clear();
    }
  }

  void _removeTableTag(String tag) {
    context.read<AuditCubit>().removeTableTag(tag);
  }

  void _addRoleTag(String tag) {
    if (tag.isNotEmpty) {
      context.read<AuditCubit>().addRoleTag(tag);
      _roleFilter.clear();
    }
  }

  void _removeRoleTag(String tag) {
    context.read<AuditCubit>().removeRoleTag(tag);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _ancapYellow,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _dateFilter.text = DateFormat("yyyy-MM-dd").format(picked);
      context.read<AuditCubit>().setDateFilter(_dateFilter.text);
    }
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
            // Sidebar with dark background
            const Sidebar(showChatFeatures: false),

            // Main content area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header that spans full width
                  _buildHeader(),

                  // Content with padding
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildFilters(),
                          const SizedBox(height: 24),
                          BlocBuilder<AuditCubit, AuditState>(
                            builder: (context, state) {
                              if (state is AuditLoading) {
                                return _buildLoadingIndicator();
                              } else if (state is AuditError) {
                                return _buildErrorMessage(state.message);
                              } else if (state is AuditLoaded) {
                                return _buildAuditTable(state);
                              } else {
                                return const SizedBox();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_ancapYellow),
            ),
            const SizedBox(height: 16),
            Text(
              "Loading audit records...",
              style: GoogleFonts.inter(
                color: _foreground,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String errorMessage) {
    return Expanded(
      child: _buildGlassEffectContainer(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                "Error loading audit records",
                style: GoogleFonts.inter(
                  color: _foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.read<AuditCubit>().fetchAuditRecords(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ancapYellow,
                  foregroundColor: _ancapDarkBlue,
                ),
                child: const Text("Retry"),
              ),
            ],
          ),
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
              Icons.analytics_outlined,
              color: _ancapDarkBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Auditoría",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: _foreground,
                  fontSize: 18,
                ),
              ),
              Text(
                "Registro de consultas y operaciones",
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

  Widget _buildFilters() {
    return _buildGlassEffectContainer(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Filtros",
                style: GoogleFonts.inter(
                  color: _foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.cleaning_services_outlined),
                color: _ancapYellow,
                tooltip: "Limpiar filtros",
                onPressed: _clearAllFilters,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _usernameFilter,
                  style: GoogleFonts.inter(
                    color: _foreground,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: "Usuario",
                    labelStyle: GoogleFonts.inter(
                      color: _mutedForeground,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: _mutedForeground,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: _border.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: _ancapYellow, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _roleFilter,
                      style: GoogleFonts.inter(
                        color: _foreground,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        labelText: "Rol",
                        labelStyle: GoogleFonts.inter(
                          color: _mutedForeground,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: _mutedForeground,
                          size: 18,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            size: 18,
                          ),
                          color: _ancapYellow,
                          onPressed: () => _addRoleTag(_roleFilter.text.trim()),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: _border.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: _ancapYellow, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (value) => _addRoleTag(value.trim()),
                    ),
                    BlocBuilder<AuditCubit, AuditState>(
                      builder: (context, state) {
                        if (state is AuditLoaded) {
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            height: 32,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: state.selectedRoleTags
                                  .map((tag) => _buildRoleTag(tag))
                                  .toList(),
                            ),
                          );
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _dateFilter,
                  readOnly: true,
                  style: GoogleFonts.inter(
                    color: _foreground,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: "Fecha",
                    labelStyle: GoogleFonts.inter(
                      color: _mutedForeground,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      color: _mutedForeground,
                      size: 18,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.date_range,
                        size: 18,
                      ),
                      color: _ancapYellow,
                      onPressed: () => _selectDate(context),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide:
                          BorderSide(color: _border.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: _ancapYellow, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onTap: () => _selectDate(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _tablesFilter,
                      style: GoogleFonts.inter(
                        color: _foreground,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        labelText: "Tablas consultadas",
                        labelStyle: GoogleFonts.inter(
                          color: _mutedForeground,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.table_chart_outlined,
                          color: _mutedForeground,
                          size: 18,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            size: 18,
                          ),
                          color: _ancapYellow,
                          onPressed: () =>
                              _addTableTag(_tablesFilter.text.trim()),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: _border.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: _ancapYellow, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (value) => _addTableTag(value.trim()),
                    ),
                    BlocBuilder<AuditCubit, AuditState>(
                      builder: (context, state) {
                        if (state is AuditLoaded) {
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            height: 32,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: state.selectedTableTags
                                  .map((tag) => _buildTableTag(tag))
                                  .toList(),
                            ),
                          );
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterField(
                  controller: _costFilter,
                  label: "Costo",
                  icon: Icons.attach_money_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(color: _foreground, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: _mutedForeground, fontSize: 14),
        prefixIcon: Icon(icon, color: _mutedForeground, size: 18),
        filled: true,
        fillColor: Colors.transparent,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: _border.withValues(alpha: 0.3)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: _ancapYellow, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildTableTag(String tag) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: _ancapYellow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ancapYellow.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          Text(
            tag,
            style: GoogleFonts.inter(
              color: _ancapYellow,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          InkWell(
            onTap: () => _removeTableTag(tag),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.close,
                size: 14,
                color: _ancapYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTag(String tag) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: _ancapYellow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ancapYellow.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          Text(
            tag,
            style: GoogleFonts.inter(
              color: _ancapYellow,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          InkWell(
            onTap: () => _removeRoleTag(tag),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.close,
                size: 14,
                color: _ancapYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTable(AuditLoaded state) {
    return Expanded(
      child: _buildGlassEffectContainer(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Registros de auditoría",
                  style: GoogleFonts.inter(
                    color: _foreground,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${state.filteredRecords.length} registros encontrados",
                  style: GoogleFonts.inter(
                    color: _mutedForeground,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double availableWidth = constraints.maxWidth;
                  final double usernameWidth = availableWidth * 0.18;
                  final double roleWidth = availableWidth * 0.15;
                  final double dateWidth = availableWidth * 0.22;
                  final double tablesWidth = availableWidth * 0.30;
                  final double costWidth = availableWidth * 0.15;

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SizedBox(
                      width: availableWidth,
                      child: DataTable(
                        headingRowColor: WidgetStateColor.resolveWith(
                          (states) => _border.withValues(alpha: 0.1),
                        ),
                        dataRowColor: WidgetStateColor.resolveWith(
                          (states) => Colors.transparent,
                        ),
                        headingTextStyle: GoogleFonts.inter(
                          color: _foreground,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        dataTextStyle: GoogleFonts.inter(
                          color: _foreground,
                          fontSize: 14,
                        ),
                        columnSpacing: 8,
                        horizontalMargin: 8,
                        columns: [
                          DataColumn(
                            label: SizedBox(
                              width: usernameWidth,
                              child: const Text("Usuario"),
                            ),
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: roleWidth,
                              child: const Text("Rol"),
                            ),
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: dateWidth,
                              child: const Text("Fecha"),
                            ),
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: tablesWidth,
                              child: const Text("Tablas consultadas"),
                            ),
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: costWidth,
                              child: const Text("Costo"),
                            ),
                          ),
                        ],
                        rows: state.filteredRecords.map((record) {
                          return DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: usernameWidth,
                                  child: Text(record.displayName),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: roleWidth,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: IntrinsicWidth(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _ancapYellow.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _ancapYellow.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          record.role,
                                          style: GoogleFonts.inter(
                                            color: _ancapYellow,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: dateWidth,
                                  child: Text(
                                    DateFormat("yyyy-MM-dd HH:mm")
                                        .format(record.date),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: tablesWidth,
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children:
                                        record.consultedTables.map((table) {
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          right: 4,
                                          bottom: 4,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _ancapYellow.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _ancapYellow.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          table,
                                          style: GoogleFonts.inter(
                                            color: _ancapYellow,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: costWidth,
                                  child: Text(
                                    "\$${record.cost.toStringAsFixed(2)}",
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
