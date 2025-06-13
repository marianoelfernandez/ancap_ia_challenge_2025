class AuditRecord {
  final String username;
  final String role;
  final DateTime date;
  final List<String> consultedTables;
  final double cost;

  AuditRecord({
    required this.username,
    required this.role,
    required this.date,
    required this.consultedTables,
    required this.cost,
  });

  // Helper method to format the list of consulted tables as a string
  String get consultedTablesFormatted {
    return consultedTables.join(", ");
  }
}
