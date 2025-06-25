import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:google_fonts/google_fonts.dart";

const Color _foreground = Color(0xFFF8FAFC);
const Color _ancapDarkBlue = Color(0xFF002A53);

class SqlResponseWidget extends StatefulWidget {
  final String sqlQuery;

  const SqlResponseWidget({super.key, required this.sqlQuery});

  @override
  State<SqlResponseWidget> createState() => _SqlResponseWidgetState();
}

class _SqlResponseWidgetState extends State<SqlResponseWidget> {
  late TextEditingController _sqlController;
  bool _isExpanded = false; // Collapsed by default

  @override
  void initState() {
    super.initState();
    _sqlController = TextEditingController(text: widget.sqlQuery);
  }

  @override
  void dispose() {
    _sqlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: _isExpanded ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: _foreground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Consulta SQL",
                        style: GoogleFonts.inter(
                          color: _foreground,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isExpanded)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: _foreground),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: _sqlController.text),
                      );
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
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isExpanded ? 1.0 : 0.0,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: TextField(
                      controller: _sqlController,
                      maxLines: null,
                      style: GoogleFonts.firaCode(
                        color: _foreground,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      cursorColor: _foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
