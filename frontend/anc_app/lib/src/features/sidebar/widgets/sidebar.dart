import "dart:ui";

import "package:anc_app/src/models/chat_history_item.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

const Color _ancapYellow = Color(0xFFFFC107);
const Color _ancapDarkBlue = Color(0xFF002A53);

const Color _foreground = Color(0xFFF8FAFC);
const Color _mutedForeground = Color(0xFF808EA2);
const Color _border = Color(0xFF1A1F29);

final Color _glassBackground = Colors.white.withValues(alpha: 0.03);
const Color _glassBorder = Color(0x1AFFFFFF);

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  @override
  Widget build(BuildContext context) {
    return _buildSidebar();
  }
}

Widget _buildSidebar() {
  return _buildGlassEffectContainer(
    margin: EdgeInsets.zero,
    borderRadius: 0,
    child: SizedBox(
      width: 300,
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
    padding: const EdgeInsets.all(24.0),
    child: Container(
      padding: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: _border.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
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
                  blurRadius: 20,
                ),
                BoxShadow(
                  color: _ancapYellow.withValues(alpha: 0.2),
                  blurRadius: 40,
                ),
                BoxShadow(
                  color: _ancapYellow.withValues(alpha: 0.1),
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
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: TextField(
      style: GoogleFonts.inter(color: _foreground),
      decoration: InputDecoration(
        hintText: "Search conversations...",
        hintStyle: GoogleFonts.inter(color: _mutedForeground, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: _mutedForeground, size: 16),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
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
  final List<ChatHistoryItem> chatHistory = [
    ChatHistoryItem(id: "1", title: "Sales Analysis", date: "2 hours ago"),
    ChatHistoryItem(id: "2", title: "Revenue Forecast", date: "Yesterday"),
    ChatHistoryItem(id: "3", title: "Market Trends", date: "2 days ago"),
  ];
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
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
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: chatHistory.length,
              itemBuilder: (context, index) {
                final chat = chatHistory[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {/* Handle chat selection */},
                      borderRadius: BorderRadius.circular(12.0),
                      hoverColor: _foreground.withValues(alpha: 0.05),
                      child: _buildGlassEffectContainer(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.message_outlined,
                              color: _ancapYellow,
                              size: 16,
                            ),
                            const SizedBox(width: 12),
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
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: _mutedForeground,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 8),
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
