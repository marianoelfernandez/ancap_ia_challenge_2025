import "dart:ui";
import "dart:math" as math;
import "package:anc_app/src/features/sidebar/cubits/sidebar_cubit.dart";
import "package:anc_app/src/features/auth/cubits/auth_cubit.dart";
import "package:anc_app/src/models/conversation.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:google_fonts/google_fonts.dart";
import "package:anc_app/src/router/router.dart";
import "package:anc_app/src/router/screen_params.dart";
import "package:intl/intl.dart";

const Color _ancapYellow = Color(0xFFFFC107);
const Color _ancapDarkBlue = Color(0xFF002A53);

const Color _foreground = Color(0xFFF8FAFC);
const Color _mutedForeground = Color(0xFF808EA2);
const Color _border = Color(0xFF1A1F29);

final Color _glassBackground = Colors.white.withValues(alpha: 0.03);
const Color _glassBorder = Color(0x1AFFFFFF);

class Sidebar extends StatefulWidget {
  final bool showChatFeatures;
  final Function(String conversationId, String title)? onConversationSelected;

  const Sidebar({
    super.key,
    this.showChatFeatures = false,
    this.onConversationSelected,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late SidebarCubit _sidebarCubit;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _sidebarCubit = SidebarCubit();
    _searchController = TextEditingController();
    if (widget.showChatFeatures) {
      _sidebarCubit.loadRecentConversations();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sidebarCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _sidebarCubit,
      child: _buildSidebar(widget.showChatFeatures),
    );
  }

  Widget _buildSidebar(bool showChatFeatures) {
    return _buildGlassEffectContainer(
      margin: EdgeInsets.zero,
      borderRadius: 0,
      child: SizedBox(
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserProfile(),
            _buildNavigationTabs(),
            if (showChatFeatures) _buildSearchInput(),
            if (showChatFeatures) _buildChatHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return BlocBuilder<SidebarCubit, SidebarState>(
      builder: (context, state) {
        final user = state.currentUser;
        final userName = user?.name ?? "Guest User";
        final userRole = user?.role ?? "No Role";

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.only(bottom: 24.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _border.withValues(alpha: 0.1)),
              ),
            ),
            child: _UserProfileWithSignOut(
              userName: userName,
              userRole: userRole,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Container(
        padding: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: _border.withValues(alpha: 0.1))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNavigationTab(
              icon: Icons.chat_bubble_outline,
              label: "Chatbot",
              route: AppRoute.chatbot,
            ),
            const SizedBox(height: 8),
            _buildNavigationTab(
              icon: Icons.dashboard_outlined,
              label: "Dashboard",
              route: AppRoute.dashboard,
            ),
            const SizedBox(height: 8),
            _buildNavigationTab(
              icon: Icons.analytics_outlined,
              label: "Auditoría",
              route: AppRoute.audit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTab({
    required IconData icon,
    required String label,
    required AppRoute route,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (route == AppRoute.chatbot) {
            context.read<SidebarCubit>().clearSelectedConversation();
            context.goToAppRoute(AppRoute.chatbot);
          } else {
            context.goNamed(route.name);
          }
        },
        borderRadius: BorderRadius.circular(8.0),
        hoverColor: _foreground.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: _ancapYellow,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: _foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return BlocBuilder<SidebarCubit, SidebarState>(
      buildWhen: (previous, current) =>
          previous.searchQuery != current.searchQuery,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            style: GoogleFonts.inter(color: _foreground),
            decoration: InputDecoration(
              hintText: "Buscar conversaciones",
              hintStyle:
                  GoogleFonts.inter(color: _mutedForeground, fontSize: 14),
              prefixIcon:
                  const Icon(Icons.search, color: _mutedForeground, size: 16),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: _mutedForeground,
                        size: 16,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        context.read<SidebarCubit>().clearSearchQuery();
                      },
                    )
                  : null,
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
                ),
              ),
            ),
            onChanged: (query) {
              context.read<SidebarCubit>().updateSearchQuery(query);
            },
            controller: _searchController,
          ),
        );
      },
    );
  }

  Widget _buildChatHistoryList() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: BlocBuilder<SidebarCubit, SidebarState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Conversaciones recientes",
                      style: GoogleFonts.inter(
                        color: _mutedForeground,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (state.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_ancapYellow),
                        ),
                      ),
                    if (!state.isLoading && state.error != null)
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: _mutedForeground,
                          size: 16,
                        ),
                        onPressed: () =>
                            context.read<SidebarCubit>().refreshConversations(),
                        tooltip: "Reintentar cargar conversaciones",
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (state.error != null && !state.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildGlassEffectContainer(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Error al cargar conversaciones",
                              style: GoogleFonts.inter(
                                color: _foreground,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: state.filteredConversations.isEmpty && !state.isLoading
                      ? Center(
                          child: Text(
                            state.searchQuery.isNotEmpty
                                ? "No se encontraron conversaciones"
                                : state.error == null
                                    ? "No hay conversaciones"
                                    : "No hay conversaciones para mostrar",
                            style: GoogleFonts.inter(
                              color: _mutedForeground,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white,
                                Colors.white,
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.05, 0.95, 1.0],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                            ),
                            itemCount: state.filteredConversations.length,
                            itemBuilder: (context, index) {
                              final conversation =
                                  state.filteredConversations[index];
                              final DateTime createdDate = conversation.created;
                              final String formattedDate =
                                  _formatConversationDate(createdDate);
                              final String title =
                                  _extractConversationTitle(conversation);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      context
                                          .read<SidebarCubit>()
                                          .setSelectedConversation(
                                            conversation.id,
                                          );

                                      context.goToAppRoute(
                                        AppRoute.chatbot,
                                        queryParams: ChatbotParams(
                                          conversation: conversation.id,
                                        ),
                                      );

                                      if (widget.onConversationSelected !=
                                          null) {
                                        widget.onConversationSelected!(
                                          conversation.id,
                                          title,
                                        );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12.0),
                                    hoverColor:
                                        _foreground.withValues(alpha: 0.05),
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  style: GoogleFonts.inter(
                                                    color: _foreground,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                                      formattedDate,
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
                ),
              ],
            );
          },
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

  String _formatConversationDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes} min ago";
    } else if (difference.inDays < 1) {
      return "${difference.inHours} hours ago";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    } else {
      return DateFormat("MMM d, yyyy").format(date);
    }
  }

  String _extractConversationTitle(Conversation conversation) {
    try {
      if (conversation.conversation.isNotEmpty) {
        return conversation.conversation.split("\n").first.trim().substring(
              0,
              math.min(
                50,
                conversation.conversation.split("\n").first.trim().length,
              ),
            );
      }
      return "Conversation ${conversation.id.substring(0, math.min(8, conversation.id.length))}";
    } catch (e) {
      return "Conversation ${conversation.id.substring(0, math.min(8, conversation.id.length))}";
    }
  }
}

class _UserProfileWithSignOut extends StatefulWidget {
  final String userName;
  final String userRole;

  const _UserProfileWithSignOut({
    required this.userName,
    required this.userRole,
  });

  @override
  State<_UserProfileWithSignOut> createState() =>
      _UserProfileWithSignOutState();
}

class _UserProfileWithSignOutState extends State<_UserProfileWithSignOut> {
  bool _isHovered = false;

  Future<void> _handleSignOut() async {
    try {
      final authCubit = context.read<AuthCubit>();
      await authCubit.signOut();

      final sidebarCubit = context.read<SidebarCubit>();
      await sidebarCubit.signOut();

      if (mounted) {
        await context.goToAppRoute(AppRoute.initial);
      }
    } catch (e) {
      debugPrint("Error during sign out: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al cerrar sesión"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleSignOut,
        onHover: (hovering) {
          setState(() {
            _isHovered = hovering;
          });
        },
        borderRadius: BorderRadius.circular(8.0),
        hoverColor: _foreground.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isHovered
                      ? LinearGradient(
                          colors: [
                            Colors.red.withValues(alpha: 0.8),
                            Colors.red.withValues(alpha: 0.6),
                          ],
                        )
                      : const LinearGradient(
                          colors: [
                            _ancapYellow,
                            Color(0xFFF59E0B),
                          ],
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered
                          ? Colors.red.withValues(alpha: 0.3)
                          : _ancapYellow.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                    BoxShadow(
                      color: _isHovered
                          ? Colors.red.withValues(alpha: 0.2)
                          : _ancapYellow.withValues(alpha: 0.2),
                      blurRadius: 40,
                    ),
                    BoxShadow(
                      color: _isHovered
                          ? Colors.red.withValues(alpha: 0.1)
                          : _ancapYellow.withValues(alpha: 0.1),
                      blurRadius: 60,
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isHovered ? Icons.logout : Icons.person_outline,
                    key: ValueKey(_isHovered),
                    color: _isHovered ? Colors.white : _ancapDarkBlue,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: _isHovered ? Colors.red : _foreground,
                        fontSize: 16,
                      ),
                      child: Text(
                        _isHovered ? "Cerrar sesión" : widget.userName,
                      ),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.inter(
                        color: _isHovered
                            ? Colors.red.withValues(alpha: 0.7)
                            : _mutedForeground,
                        fontSize: 14,
                      ),
                      child: Text(
                        _isHovered ? "Salir de la cuenta" : widget.userRole,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
