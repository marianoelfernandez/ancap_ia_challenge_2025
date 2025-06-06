import "dart:async";
import "package:flutter/material.dart";
import "dart:developer" as developer; // Import for log
import "package:go_router/go_router.dart";
import "package:google_fonts/google_fonts.dart";
import "package:anc_app/src/router/router.dart";

const Color _backgroundStart = Color(0xFF060912);
const Color _backgroundMid = Color(0xFF0B101A);
const Color _backgroundEnd = Color(0xFF050505);
const Color _ancapYellow = Color(0xFFFFC107);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    developer.log("SplashScreen initState called", name: "SplashScreen"); // <--- ADD THIS

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();

    Timer(const Duration(seconds: 3), () {
      developer.log("SplashScreen Timer expired, navigating to chatbot", name: "SplashScreen"); // <--- ADD THIS
      if (mounted) {
        context.goNamed(AppRoute.chatbot.name);
      } else {
        developer.log("SplashScreen Timer: NOT MOUNTED, cannot navigate", name: "SplashScreen"); // <--- ADD THIS
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    developer.log("SplashScreen build called", name: "SplashScreen"); // <--- ADD THIS
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_backgroundStart, _backgroundMid, _backgroundEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              "ANC-APP",
              style: GoogleFonts.inter(
                fontSize: 60,
                fontWeight: FontWeight.w900,
                color: _ancapYellow,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: _ancapYellow.withValues(alpha: 0.7),
                    offset: Offset.zero,
                  ),
                  Shadow(
                    blurRadius: 20.0,
                    color: _ancapYellow.withValues(alpha: 0.5),
                    offset: Offset.zero,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
