import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:google_fonts/google_fonts.dart";

const Color _foreground = Color(0xFFF8FAFC);
const Color _ancapDarkBlue = Color(0xFF002A53);

class SqlResponseWidget extends StatelessWidget {
  final String sqlQuery;

  const SqlResponseWidget({super.key, required this.sqlQuery});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Consulta SQL Generada",
                style: GoogleFonts.inter(
                  color: _foreground,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: _foreground),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: sqlQuery));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("SQL Query copiado al portapapeles!"),
                      backgroundColor: _ancapDarkBlue,
                    ),
                  );
                },
                tooltip: "Copiar SQL",
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                sqlQuery,
                style: GoogleFonts.firaCode(
                  color: _foreground,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
