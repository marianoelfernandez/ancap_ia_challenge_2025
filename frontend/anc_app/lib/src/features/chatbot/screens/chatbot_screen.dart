import "dart:ui"; // For BackdropFilter
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

// --- Color Definitions (directly in file for now) ---
const Color _ancapYellow = Color(0xFFFFC107); // hsl(45, 100%, 55%)
// const Color _ancapBlue = Color(0xFF0059B3); // Unused for now
const Color _ancapDarkBlue = Color(0xFF003E7E); // hsl(210, 100%, 25%)

const Color _backgroundStart =
    Color(0xFF0F172A); // slate-950 approx (CSS: 220 25% 8%)
const Color _backgroundMid =
    Color(0xFF1E293B); // zinc-900 approx (CSS: 220 25% 15%)
const Color _backgroundEnd = Color(0xFF171717); // neutral-900 approx

const Color _foreground = Color(0xFFF8FAFC); // hsl(210 40% 98%)
const Color _mutedForeground = Color(0xFF94A3B8); // hsl(215 20% 65%)
const Color _border = Color(0xFF334155); // hsl(220 25% 20%)

final Color _glassBackground = Colors.white.withOpacity(0.05);
const Color _glassBorder = Color(0x1AFFFFFF); // rgba(255, 255, 255, 0.1)

// --- Message Data Model ---
class ChatMessage {
  final String id;
  final String text;
  final bool isAi;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isAi,
    required this.timestamp,
  });
}

// --- Chat History Item Data Model ---
class ChatHistoryItem {
  final String id;
  final String title;
  final String date;

  ChatHistoryItem({
    required this.id,
    required this.title,
    required this.date,
  });
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: "1",
      text:
          "Hello! I'm your ANCAP AI Assistant. How can I help you analyze your business data today?",
      isAi: true,
      timestamp: DateTime.now(),
    ),
  ];
  final TextEditingController _inputController = TextEditingController();
  final List<ChatHistoryItem> _chatHistory = [
    ChatHistoryItem(id: "1", title: "Sales Analysis", date: "2 hours ago"),
    ChatHistoryItem(id: "2", title: "Revenue Forecast", date: "Yesterday"),
    ChatHistoryItem(id: "3", title: "Market Trends", date: "2 days ago"),
  ];

  void _handleSend() {
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
    });
    _inputController.clear();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add(
          ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            text:
                "I'm analyzing your request. Let me process that data for you...",
            isAi: true,
            timestamp: DateTime.now(),
          ),
        );
      });
    });
  }

  Widget _buildGlassEffectContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0), // --radius: 0.5rem from CSS
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: _glassBackground,
            borderRadius: BorderRadius.circular(12.0),
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
    final bool isSmallScreen =
        screenWidth < 768; // Example breakpoint for collapsing sidebar

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
            // Sidebar (conditionally shown or drawer on small screens)
            if (!isSmallScreen) _buildSidebar(),

            // Main Chat Area
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
      // Consider adding a Drawer for small screens if sidebar is hidden
      // drawer: isSmallScreen ? _buildSidebar() : null,
    );
  }

  Widget _buildSidebar() {
    return _buildGlassEffectContainer(
      margin: const EdgeInsets.fromLTRB(24, 24, 0, 24), // m-6, mr-0
      child: SizedBox(
        width: 300, // w-[300px]
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserProfile(),
            _buildSearchInput(),
            _buildChatHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return Padding(
      padding: const EdgeInsets.all(24.0), // p-6
      child: Container(
        padding: const EdgeInsets.only(bottom: 24.0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _border.withOpacity(0.1))),
        ),
        child: Row(
          children: [
            Container(
              width: 48, // w-12
              height: 48, // h-12
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    _ancapYellow,
                    Color(0xFFF59E0B),
                  ],
                ), // yellow-400 to yellow-500
                boxShadow: [
                  // glow-effect
                  BoxShadow(
                    color: _ancapYellow.withOpacity(0.3),
                    blurRadius: 20,
                  ),
                  BoxShadow(
                    color: _ancapYellow.withOpacity(0.2),
                    blurRadius: 40,
                  ),
                  BoxShadow(
                    color: _ancapYellow.withOpacity(0.1),
                    blurRadius: 60,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_outline,
                color: _ancapDarkBlue,
                size: 24,
              ), // User icon
            ),
            const SizedBox(width: 16), // gap-4
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "John Doe",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: _foreground,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Business Analyst",
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

  Widget _buildSearchInput() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // p-4
      child: TextField(
        style: GoogleFonts.inter(color: _foreground),
        decoration: InputDecoration(
          hintText: "Search conversations...",
          hintStyle: GoogleFonts.inter(color: _mutedForeground, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: _mutedForeground, size: 16),
          filled: true,
          fillColor: Colors.transparent, // Handled by glass effect
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none, // Border handled by glass effect
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: _ancapYellow,
              width: 1,
            ), // Ring effect on focus
          ),
        ),
      ),
    );
  }

  Widget _buildChatHistoryList() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0), // p-4
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0), // mb-4
              child: Text(
                "Recent Conversations",
                style: GoogleFonts.inter(
                  color: _mutedForeground,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final chat = _chatHistory[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0), // space-y-2
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {/* Handle chat selection */},
                        borderRadius: BorderRadius.circular(12.0),
                        hoverColor: _foreground.withOpacity(0.05),
                        child: _buildGlassEffectContainer(
                          padding: const EdgeInsets.all(12.0), // p-3
                          child: Row(
                            children: [
                              Icon(
                                Icons.message_outlined,
                                color: _ancapYellow,
                                size: 16,
                              ), // MessageSquare
                              const SizedBox(width: 12), // gap-3
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      chat.title,
                                      style: GoogleFonts.inter(
                                        color: _foreground,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4), // mt-1
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          color: _mutedForeground,
                                          size: 12,
                                        ), // Clock
                                        const SizedBox(width: 8), // gap-2
                                        Text(
                                          chat.date,
                                          style: GoogleFonts.inter(
                                            color: _mutedForeground,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildChatHeader() {
    return _buildGlassEffectContainer(
      margin: const EdgeInsets.all(0), // No margin for header, spans full width
      padding: const EdgeInsets.all(24.0), // p-6
      // Removed unnecessary Container, decoration moved to Row's parent in _buildGlassEffectContainer or applied directly if needed.
      // The BoxDecoration for border is now part of the Row's direct child Container.
      child: Container(
        // This container is kept to apply the bottom border
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _border.withOpacity(0.1))),
        ),
        child: Row(
          children: [
            Container(
              width: 40, // w-10
              height: 40, // h-10
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    _ancapYellow,
                    Color(0xFFF59E0B),
                  ],
                ), // yellow-400 to yellow-500
                boxShadow: [
                  // glow-effect
                  BoxShadow(
                    color: _ancapYellow.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: _ancapYellow.withOpacity(0.2),
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
        padding: const EdgeInsets.all(24.0), // p-6
        reverse: true, // To keep latest messages at the bottom
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[
              _messages.length - 1 - index]; // Display in reverse for UI
          final isAi = message.isAi;
          return Align(
            alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ), // max-w-[80%]
              margin: const EdgeInsets.symmetric(
                vertical: 8.0,
              ), // space-y-6 (approx)
              padding: const EdgeInsets.all(16.0), // p-4
              decoration: BoxDecoration(
                color: isAi
                    ? null
                    : _ancapYellow, // AI uses glass, user uses yellow
                borderRadius: BorderRadius.circular(20.0), // rounded-2xl
                // Apply glass effect only for AI messages
                border: isAi ? Border.all(color: _glassBorder, width: 1) : null,
                boxShadow: isAi
                    ? null
                    : [
                        // Subtle shadow for user messages
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: isAi
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(
                        19.0,
                      ), // Inner radius for backdrop filter
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                _glassBackground, // This color is seen through the blur
                            borderRadius: BorderRadius.circular(19.0),
                          ),
                          padding: const EdgeInsets.all(
                            0.1,
                          ), // Minimal padding to ensure content is within blur
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

  Widget _buildInputArea() {
    return _buildGlassEffectContainer(
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.all(24.0), // p-6
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: _border.withOpacity(0.1))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                style: GoogleFonts.inter(color: _foreground, fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Ask anything about your business data...",
                  hintStyle:
                      GoogleFonts.inter(color: _mutedForeground, fontSize: 15),
                  filled: true,
                  fillColor: Colors.transparent, // Handled by glass effect
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide:
                        BorderSide.none, // Border handled by glass effect
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: _ancapYellow,
                      width: 1.5,
                    ), // Ring effect
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            const SizedBox(width: 16), // gap-4
            ElevatedButton(
              onPressed: _handleSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, // To show gradient through
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
                  ), // yellow-400 to yellow-500
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ), // Match input field height
                  child: Icon(Icons.send, color: _ancapDarkBlue, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
