import "dart:ui";
import "dart:math";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:anc_app/src/models/chat_message.dart";
import "package:anc_app/src/features/sidebar/widgets/sidebar.dart";
import "package:anc_app/src/features/chatbot/services/chat_service.dart";
import "package:get_it/get_it.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:anc_app/src/features/auth/cubits/auth_cubit.dart";
import "package:anc_app/src/router/router.dart";

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
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: "1",
      text:
          "Hola! Soy tu asistente de ANCAP. ¿Cómo puedo ayudarte a analizar tus datos de negocio hoy?",
      isAi: true,
      timestamp: DateTime.now(),
    ),
  ];
  final TextEditingController _inputController = TextEditingController();
  String? _currentConversationId;
  final ChatService _chatService = GetIt.instance<ChatService>();
  bool _isAiTyping = false;

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
  }

  void _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          isAi: false,
          timestamp: DateTime.now(),
        ),
      );
      _isAiTyping = true;
    });
    _inputController.clear();

    try {
      final response = await _chatService.sendMessage(
        text,
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
    } catch (e) {
      setState(() {
        _isAiTyping = false;
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: "Lo siento en este momento no puedo ayudarte",
            isAi: true,
            timestamp: DateTime.now(),
          ),
        );
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
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 768;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (!state.isAuthenticated) {
          context.goToAppRoute(AppRoute.initial);
        }
      },
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
              const Sidebar(showChatFeatures: true),
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
              ), // Bot icon
            ),
            const SizedBox(width: 12), // gap-3
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
      child: ListView.builder(
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
            alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              margin: const EdgeInsets.symmetric(
                vertical: 8.0,
              ),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isAi ? null : _ancapYellow,
                borderRadius: BorderRadius.circular(8.0),
                border: isAi ? Border.all(color: _glassBorder, width: 1) : null,
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
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _glassBackground,
                            borderRadius: BorderRadius.circular(8.0),
                            backgroundBlendMode: BlendMode.color,
                          ),
                          padding: const EdgeInsets.all(
                            0.1,
                          ),
                          child: Text(
                            message.text,
                            style: GoogleFonts.inter(
                              color: _foreground,
                              fontSize: 14,
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
                controller: _inputController,
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
