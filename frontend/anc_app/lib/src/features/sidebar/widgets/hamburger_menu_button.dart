import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

const Color _foreground = Color(0xFFF8FAFC);

class HamburgerMenuButton extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onPressed;
  final Color? color;
  final double size;

  const HamburgerMenuButton({
    super.key,
    required this.isOpen,
    required this.onPressed,
    this.color,
    this.size = 24.0,
  });

  @override
  State<HamburgerMenuButton> createState() => _HamburgerMenuButtonState();
}

class _HamburgerMenuButtonState extends State<HamburgerMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _topBarAnimation;
  late Animation<double> _middleBarAnimation;
  late Animation<double> _bottomBarAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _topBarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _middleBarAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _bottomBarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HamburgerMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? _foreground;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  children: [
                    // Top bar
                    Positioned(
                      top: widget.size * 0.2,
                      left: 0,
                      right: 0,
                      child: Transform.rotate(
                        angle: _topBarAnimation.value * 0.785, // 45 degrees
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            _topBarAnimation.value * (widget.size * 0.15),
                          ),
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Middle bar
                    Positioned(
                      top: widget.size * 0.45,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: _middleBarAnimation.value,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                    // Bottom bar
                    Positioned(
                      top: widget.size * 0.7,
                      left: 0,
                      right: 0,
                      child: Transform.rotate(
                        angle:
                            -_bottomBarAnimation.value * 0.785, // -45 degrees
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            -_bottomBarAnimation.value * (widget.size * 0.15),
                          ),
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  final bool isMenuOpen;
  final List<Widget>? actions;

  const MobileAppBar({
    super.key,
    required this.title,
    this.showMenuButton = true,
    this.onMenuPressed,
    this.isMenuOpen = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: showMenuButton
          ? HamburgerMenuButton(
              isOpen: isMenuOpen,
              onPressed: onMenuPressed ?? () {},
            )
          : null,
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: _foreground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.1),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
