import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:google_fonts/google_fonts.dart";
import "package:anc_app/src/features/chatbot/services/chat_service.dart";
import "package:get_it/get_it.dart";

const Color _foreground = Color(0xFFF8FAFC);
const Color _ancapDarkBlue = Color(0xFF002A53);
const Color _ancapYellow = Color(0xFFFFC107);

class SqlResponseWidget extends StatefulWidget {
  final String sqlQuery;
  final String? conversationId;
  final Function(String)? onSqlExecuted;

  const SqlResponseWidget({
    super.key,
    required this.sqlQuery,
    this.conversationId,
    this.onSqlExecuted,
  });

  @override
  State<SqlResponseWidget> createState() => _SqlResponseWidgetState();
}

class _SqlResponseWidgetState extends State<SqlResponseWidget> {
  late TextEditingController _sqlController;
  final ChatService _chatService = GetIt.instance<ChatService>();
  bool _isExecuting = false;
  bool _isExpanded = false; // Collapsed by default

  @override
  void initState() {
    super.initState();
    _sqlController = TextEditingController(text: widget.sqlQuery);
  }

  Future<void> _executeSql() async {
    if (_sqlController.text.trim().isEmpty) return;

    setState(() {
      _isExecuting = true;
    });

    try {
      final response = await _chatService.executeSqlQuery(
        _sqlController.text.trim(),
        conversationId: widget.conversationId,
      );

      if (widget.onSqlExecuted != null) {
        widget.onSqlExecuted!(response["response"] as String);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("SQL ejecutado exitosamente!"),
            backgroundColor: _ancapDarkBlue,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error ejecutando SQL: $error"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExecuting = false;
        });
      }
    }
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
                    icon: _isExecuting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(_ancapYellow),
                            ),
                          )
                        : const Icon(Icons.play_arrow,
                            size: 18, color: _ancapYellow,),
                    onPressed: _isExecuting ? null : _executeSql,
                    tooltip: "Ejecutar SQL",
                  ),
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
