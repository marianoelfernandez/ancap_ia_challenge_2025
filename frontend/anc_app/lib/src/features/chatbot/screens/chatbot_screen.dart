import "dart:math";
import "dart:ui";

import "package:anc_app/src/features/auth/cubits/auth_cubit.dart";
import "package:anc_app/src/features/chatbot/cubit/chatbot_cubit.dart";
import "package:anc_app/src/features/chatbot/services/chat_service.dart";
import "package:anc_app/src/features/sidebar/widgets/sidebar.dart";
import "package:anc_app/src/models/chat_message.dart";
import "package:anc_app/src/router/router.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:get_it/get_it.dart";
import "package:google_fonts/google_fonts.dart";

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
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isAiTyping = false;
  late final ChatService _chatService;
  late final ChatbotCubit _chatbotCubit;
  String? _currentConversationId;

  @override
  void initState() {
    super.initState();
    // Check authentication status
    final authState = context.read<AuthCubit>().state;
    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.goToAppRoute(AppRoute.initial);
      });
    }

    _chatService = GetIt.instance<ChatService>();
    _chatbotCubit = ChatbotCubit();

    if (widget.initialConversationId != null) {
      _chatbotCubit.selectConversation(widget.initialConversationId!);
      _currentConversationId = widget.initialConversationId;
    } else {
      _addAiMessage(
        "Hola! Soy tu asistente de ANCAP. ¿En qué puedo ayudarte?",
      );
    }
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();
    _controller.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: userMessage,
          isAi: false,
          timestamp: DateTime.now(),
        ),
      );
      _isAiTyping = true;
    });

    try {
      final response = await _chatService.sendMessage(
        userMessage,
        conversationId: _currentConversationId,
      );

      setState(() {
        _isAiTyping = false;
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: response["response"] as String,
            isAi: true,
            timestamp: DateTime.now(),
          ),
        );
        _currentConversationId = response["conversation_id"] as String;
      });
    } catch (error) {
      setState(() {
        _isAiTyping = false;
        _addAiMessage("Lo siento, no te puedo ayudar en este momento.");
      });
    }
  }

  void _addAiMessage(String message) {
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: message,
          isAi: true,
          timestamp: DateTime.now(),
        ),
      );
    });
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
                  setState(() {
                    _currentConversationId = conversationId;
                  });
                  _chatbotCubit.selectConversation(conversationId);
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildAppBar(),
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

  Widget _buildAppBar() {
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

          if (state.selectedConversationId == null) {
            // Show chat interface with LLM
            return ListView.builder(
              padding: const EdgeInsets.all(24.0),
              reverse: true,
              itemCount: _messages.length + (_isAiTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isAiTyping && index == 0) {
                  return _buildTypingIndicator();
                }

                final messageIndex = _isAiTyping ? index - 1 : index;
                final message = _messages[_messages.length - 1 - messageIndex];
                final isAi = message.isAi;
                return Align(
                  alignment:
                      isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                    ),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: isAi ? _glassBackground : _ancapYellow,
                      borderRadius: BorderRadius.circular(8.0),
                      border: isAi
                          ? Border.all(color: _glassBorder, width: 1)
                          : null,
                      boxShadow: isAi
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: isAi
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              8.0,
                            ),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _glassBackground,
                                  borderRadius: BorderRadius.circular(8.0),
                                  backgroundBlendMode: BlendMode.color,
                                ),
                                padding: const EdgeInsets.all(
                                  0.1,
                                ),
                                child: MarkdownBody(
                                  data: message.text,
                                  styleSheet: MarkdownStyleSheet.fromTheme(
                                    Theme.of(context).copyWith(
                                      textTheme:
                                          Theme.of(context).textTheme.apply(
                                                bodyColor: _foreground,
                                                displayColor: _foreground,
                                              ),
                                    ),
                                  ).copyWith(
                                    p: GoogleFonts.inter(
                                      color: _foreground,
                                      fontSize: 14,
                                    ),
                                    code: GoogleFonts.firaCode(
                                      backgroundColor: Colors.grey[850],
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    codeblockPadding: const EdgeInsets.all(8),
                                    codeblockDecoration: BoxDecoration(
                                      color: Colors.grey[850],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    blockquote: GoogleFonts.inter(
                                      color: _foreground.withValues(alpha: 0.8),
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    h1: GoogleFonts.inter(
                                      color: _foreground,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h2: GoogleFonts.inter(
                                      color: _foreground,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h3: GoogleFonts.inter(
                                      color: _foreground,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    listBullet: GoogleFonts.inter(
                                      color: _foreground,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Text(
                            message.text,
                            style: GoogleFonts.inter(
                              color: _ancapDarkBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                );
              },
            );
          }

          if (state.queries.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _glassBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _glassBorder, width: 1),
                ),
                child: Text(
                  "No hay mensajes en esta conversación.",
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
                        borderRadius: BorderRadius.circular(8),
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
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _glassBorder, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _glassBackground,
                              borderRadius: BorderRadius.circular(8.0),
                              backgroundBlendMode: BlendMode.color,
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

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: _glassBorder, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              decoration: BoxDecoration(
                color: _glassBackground,
                borderRadius: BorderRadius.circular(8.0),
                backgroundBlendMode: BlendMode.color,
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: const _TypingIndicator(),
            ),
          ),
        ),
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
                controller: _controller,
                style: GoogleFonts.inter(color: _foreground, fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Habla con tu base de datos...",
                  hintStyle:
                      GoogleFonts.inter(color: _mutedForeground, fontSize: 15),
                  filled: false,
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
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _sendMessage,
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

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  __TypingIndicatorState createState() => __TypingIndicatorState();
}

class __TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final animation = Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  0.15 * index,
                  0.4 + 0.15 * index,
                  curve: Curves.decelerate,
                ),
              ),
            );
            final double jumpHeight = -9.0 * sin(pi * animation.value);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Transform.translate(
                offset: Offset(0, jumpHeight),
                child: child,
              ),
            );
          }),
        );
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: _foreground,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
