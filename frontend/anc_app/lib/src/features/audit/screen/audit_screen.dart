import "dart:ui";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:anc_app/src/features/sidebar/widgets/sidebar.dart";
import "package:anc_app/src/models/audit_record.dart";
import "package:intl/intl.dart";

// Define colors to match chatbot screen
const Color _ancapYellow = Color(0xFFFFC107);
const Color _ancapDarkBlue = Color(0xFF002A53);

const Color _backgroundStart = Color(0xFF060912);
const Color _backgroundMid = Color(0xFF0B101A);
const Color _backgroundEnd = Color(0xFF050505);

const Color _foreground = Color(0xFFF8FAFC);
const Color _mutedForeground = Color(0xFF808EA2);
const Color _border = Color(0xFF1A1F29);

final Color _glassBackground = Colors.white.withOpacity(0.03);
const Color _glassBorder = Color(0x1AFFFFFF);

class AuditScreen extends StatefulWidget {
  const AuditScreen({Key? key}) : super(key: key);

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  // Sample audit records
  final List<AuditRecord> _auditRecords = [
    AuditRecord(
      username: "john.doe",
      role: "Analyst",
      date: DateTime.now().subtract(const Duration(hours: 2)),
      consultedTables: ["sales", "inventory"],
      cost: 0.45,
    ),
    AuditRecord(
      username: "maria.garcia",
      role: "Manager",
      date: DateTime.now().subtract(const Duration(days: 1)),
      consultedTables: ["employees", "payroll"],
      cost: 0.78,
    ),
    AuditRecord(
      username: "alex.smith",
      role: "Admin",
      date: DateTime.now().subtract(const Duration(days: 2)),
      consultedTables: ["customers", "orders", "products"],
      cost: 1.25,
    ),
    AuditRecord(
      username: "sarah.johnson",
      role: "Analyst",
      date: DateTime.now().subtract(const Duration(days: 3)),
      consultedTables: ["inventory", "suppliers"],
      cost: 0.65,
    ),
    AuditRecord(
      username: "david.wilson",
      role: "Manager",
      date: DateTime.now().subtract(const Duration(days: 4)),
      consultedTables: ["sales", "marketing", "customers"],
      cost: 0.92,
    ),
  ];

  // Filtered records
  List<AuditRecord> _filteredRecords = [];

  // Filter controllers
  final TextEditingController _usernameFilter = TextEditingController();
  final TextEditingController _roleFilter = TextEditingController();
  final TextEditingController _dateFilter = TextEditingController();
  final TextEditingController _tablesFilter = TextEditingController();
  final TextEditingController _costFilter = TextEditingController();

  // Selected tags for filtering
  final Set<String> _selectedTableTags = <String>{};
  final Set<String> _selectedRoleTags = <String>{};

  @override
  void initState() {
    super.initState();
    _filteredRecords = List.from(_auditRecords);

    // Add listeners to filter controllers
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
    setState(() {
      _filteredRecords = _auditRecords.where((record) {
        final usernameMatch = _usernameFilter.text.isEmpty ||
            record.username
                .toLowerCase()
                .contains(_usernameFilter.text.toLowerCase());

        // Match if text filter is empty or matches role
        final textRoleMatch = _roleFilter.text.isEmpty ||
            record.role.toLowerCase().contains(_roleFilter.text.toLowerCase());

        // Match if no role tags selected or record's role is in selected roles
        final tagRoleMatch = _selectedRoleTags.isEmpty ||
            _selectedRoleTags.contains(record.role);

        final dateMatch = _dateFilter.text.isEmpty ||
            DateFormat("yyyy-MM-dd")
                .format(record.date)
                .contains(_dateFilter.text);

        // Match if text filter is empty or matches any table
        final textTablesMatch = _tablesFilter.text.isEmpty ||
            record.consultedTables.any(
              (table) => table
                  .toLowerCase()
                  .contains(_tablesFilter.text.toLowerCase()),
            );

        // Match if no tags selected or all selected tags are in the record's tables
        final tagTablesMatch = _selectedTableTags.isEmpty ||
            _selectedTableTags.every(
              (tag) => record.consultedTables.contains(tag),
            );

        final costMatch = _costFilter.text.isEmpty ||
            record.cost.toString().contains(_costFilter.text);

        return usernameMatch &&
            textRoleMatch &&
            (_selectedRoleTags.isEmpty || tagRoleMatch) &&
            dateMatch &&
            textTablesMatch &&
            (_selectedTableTags.isEmpty || tagTablesMatch) &&
            costMatch;
      }).toList();
    });
  }

  // Clear all filters
  void _clearAllFilters() {
    setState(() {
      _usernameFilter.clear();
      _roleFilter.clear();
      _dateFilter.clear();
      _tablesFilter.clear();
      _costFilter.clear();
      _selectedTableTags.clear();
      _selectedRoleTags.clear();
      _filteredRecords = List.from(_auditRecords);
    });
  }

  // Add a table tag to the filter
  void _addTableTag(String tag) {
    if (tag.isNotEmpty && !_selectedTableTags.contains(tag)) {
      setState(() {
        _selectedTableTags.add(tag);
        _tablesFilter.clear(); // Clear the text input after adding a tag
        _applyFilters();
      });
    }
  }

  // Remove a table tag from the filter
  void _removeTableTag(String tag) {
    setState(() {
      _selectedTableTags.remove(tag);
      _applyFilters();
    });
  }

  // Add a role tag to the filter
  void _addRoleTag(String tag) {
    if (tag.isNotEmpty && !_selectedRoleTags.contains(tag)) {
      setState(() {
        _selectedRoleTags.add(tag);
        _roleFilter.clear(); // Clear the text input after adding a tag
        _applyFilters();
      });
    }
  }

  // Remove a role tag from the filter
  void _removeRoleTag(String tag) {
    setState(() {
      _selectedRoleTags.remove(tag);
      _applyFilters();
    });
  }

  // Show date picker and update the date filter
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
            dialogBackgroundColor: const Color(0xFF1E1E1E),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateFilter.text = DateFormat("yyyy-MM-dd").format(picked);
        _applyFilters();
      });
    }
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
            const Sidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildFilters(),
                  _buildAuditTable(),
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
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.all(24.0),
      borderRadius: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _border.withOpacity(0.1))),
        ),
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
                    color: _ancapYellow.withOpacity(0.3),
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
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Auditoría",
                  style: GoogleFonts.inter(
                    color: _foreground,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
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
                icon: const Icon(
                  Icons.cleaning_services_outlined,
                  color: _ancapYellow,
                  size: 20,
                ),
                tooltip: "Limpiar filtros",
                onPressed: _clearAllFilters,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFilterField(
                  controller: _usernameFilter,
                  label: "Usuario",
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
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
                                onPressed: () =>
                                    _addRoleTag(_roleFilter.text.trim()),
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide:
                                    BorderSide(color: _border.withOpacity(0.3)),
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
                        ),
                      ],
                    ),
                    if (_selectedRoleTags.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _selectedRoleTags
                              .map((tag) => _buildRoleTag(tag))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _dateFilter,
                  readOnly: true, // Prevent keyboard from appearing
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
                      borderSide: BorderSide(color: _border.withOpacity(0.3)),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
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
                                borderSide:
                                    BorderSide(color: _border.withOpacity(0.3)),
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
                        ),
                      ],
                    ),
                    if (_selectedTableTags.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _selectedTableTags
                              .map((tag) => _buildTableTag(tag))
                              .toList(),
                        ),
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
          borderSide: BorderSide(color: _border.withOpacity(0.3)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: _ancapYellow, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  // Build a removable tag chip for table filtering
  Widget _buildTableTag(String tag) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: _ancapYellow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ancapYellow.withOpacity(0.3)),
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

  // Build a removable tag chip for role filtering
  Widget _buildRoleTag(String tag) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: _ancapYellow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ancapYellow.withOpacity(0.3)),
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

  Widget _buildAuditTable() {
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
                  "${_filteredRecords.length} registros encontrados",
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
                  // Calculate column widths as percentages of available width
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
                        headingRowColor: MaterialStateColor.resolveWith(
                          (states) => _border.withOpacity(0.1),
                        ),
                        dataRowColor: MaterialStateColor.resolveWith(
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
                            label: Container(
                              width: usernameWidth,
                              child: const Text("Usuario"),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              width: roleWidth,
                              child: const Text("Rol"),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              width: dateWidth,
                              child: const Text("Fecha"),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              width: tablesWidth,
                              child: const Text("Tablas consultadas"),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              width: costWidth,
                              child: const Text("Costo"),
                            ),
                          ),
                        ],
                        rows: _filteredRecords.map((record) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  width: usernameWidth,
                                  child: Text(record.username),
                                ),
                              ),
                              DataCell(
                                Container(
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
                                          color: _ancapYellow.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color:
                                                _ancapYellow.withOpacity(0.3),
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
                                Container(
                                  width: dateWidth,
                                  child: Text(
                                    DateFormat("yyyy-MM-dd HH:mm")
                                        .format(record.date),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
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
                                          color: _ancapYellow.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color:
                                                _ancapYellow.withOpacity(0.3),
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
                                Container(
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
