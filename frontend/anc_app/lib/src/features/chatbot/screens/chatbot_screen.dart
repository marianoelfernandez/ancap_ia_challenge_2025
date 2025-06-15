import "dart:ui";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:google_fonts/google_fonts.dart";
import "package:anc_app/src/features/chatbot/cubit/chatbot_cubit.dart";
import "package:anc_app/src/features/sidebar/widgets/sidebar.dart";

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

class ChatbotScreen extends StatefulWidget {
  final String? initialConversationId;

  const ChatbotScreen({super.key, this.initialConversationId});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  late final ChatbotCubit _chatbotCubit;
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chatbotCubit = ChatbotCubit();

    if (widget.initialConversationId != null) {
      _chatbotCubit.selectConversation(widget.initialConversationId!);
    }
  }

  @override
  void dispose() {
    _chatbotCubit.close();
    _inputController.dispose();
    super.dispose();
  }

  void _handleSend() {
    // TODO: This method would be updated to create a new query in the selected conversation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Creating new queries is not implemented in this demo"),
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatbotCubit,
      child: Scaffold(
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
              Sidebar(
                showChatFeatures: true,
                onConversationSelected: (conversationId) {
                  _chatbotCubit.selectConversation(conversationId);
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildChatHeader(),
                    _buildMessagesList(),
                    _buildInputArea(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return _buildGlassEffectContainer(
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.all(24.0),
      borderRadius: 0,
      child: Container(
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: _border.withValues(alpha: 0.1))),
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
                Icons.smart_toy_outlined,
                color: _ancapDarkBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ANCAP AI Assistant",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: _foreground,
                    fontSize: 18,
                  ),
                ),
                Text(
                  "Always here to help",
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

  Widget _buildMessagesList() {
    return Expanded(
      child: BlocBuilder<ChatbotCubit, ChatbotState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Text(
                state.error!,
                style: GoogleFonts.inter(color: Colors.red),
              ),
            );
          }

          if (state.queries.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _glassBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _glassBorder, width: 1),
                ),
                child: Text(
                  "Select a conversation from the sidebar or start a new one.",
                  style: GoogleFonts.inter(color: _foreground),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: state.queries.length,
            itemBuilder: (context, index) {
              final query = state.queries[index];

              return Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _ancapYellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        query.naturalQuery,
                        style: GoogleFonts.inter(
                          color: _ancapDarkBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _glassBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _glassBorder, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _glassBackground,
                              borderRadius: BorderRadius.circular(19.0),
                            ),
                            padding: const EdgeInsets.all(0.1),
                            child: Text(
                              query.output,
                              style: GoogleFonts.inter(
                                color: _foreground,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return _buildGlassEffectContainer(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(12.0),
      borderRadius: 8,
      child: Container(
        decoration: BoxDecoration(
          border:
              Border(top: BorderSide(color: _border.withValues(alpha: 0.1))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                style: GoogleFonts.inter(color: _foreground, fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Habla con tu base de datos...",
                  hintStyle:
                      GoogleFonts.inter(color: _mutedForeground, fontSize: 15),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(.0),
                    borderSide: const BorderSide(
                      color: _ancapYellow,
                      width: 1.5,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _handleSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                shadowColor: Colors.transparent,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      _ancapYellow,
                      Color(0xFFF59E0B),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 15,
                  ),
                  child:
                      const Icon(Icons.send, color: _ancapDarkBlue, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
