class AuditRecord {
  final String username;
  final String displayName;
  final String role;
  final DateTime date;
  final List<String> consultedTables;
  final double cost;

  AuditRecord({
    required this.username,
    required this.displayName,
    required this.role,
    required this.date,
    required this.consultedTables,
    required this.cost,
  });

  String get consultedTablesFormatted {
    return consultedTables.join(", ");
  }
}
