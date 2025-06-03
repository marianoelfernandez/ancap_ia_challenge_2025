import "package:flutter/material.dart";
import "dart:math" as math;
import "package:anc_app/src/features/auth/widgets/login_form.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _orbController1;
  late AnimationController _orbController2;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    _orbController1 = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _orbController2 = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _orbController1.dispose();
    _orbController2.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 1024;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0C0A09), // slate-950
              Color(0xFF18181B), // zinc-900
              Color(0xFF171717), // neutral-900
            ],
          ),
        ),
        child: Stack(
          children: [
            // AI Grid Background
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: _buildAiGrid(),
              ),
            ),

            // Floating Orbs
            _buildFloatingOrb(
              controller: _orbController1,
              left: 80,
              top: 80,
              size: 128,
              colors: [
                const Color(0xFFFBBF24).withOpacity(0.2), // yellow-400/20
                const Color(0xFFEAB308).withOpacity(0.2), // yellow-500/20
              ],
              xOffset: 100,
              yOffset: -50,
            ),

            _buildFloatingOrb(
              controller: _orbController2,
              right: 80,
              bottom: 80,
              size: 96,
              colors: [
                const Color(0xFF71717A).withOpacity(0.2), // zinc-400/20
                const Color(0xFF64748B).withOpacity(0.2), // slate-500/20
              ],
              xOffset: -80,
              yOffset: 60,
              delay: 2.0,
            ),

            _buildPulsingOrb(
              controller: _pulseController,
            ),

            // Main Content
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 1152), // max-w-6xl
                      child: isLargeScreen
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left Side - Branding
                                Expanded(
                                  child: _buildBrandingSection(isLargeScreen),
                                ),
                                const SizedBox(width: 48),
                                // Right Side - Login Form
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: LoginForm(
                                      onLoginSuccess: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text("Login Successful! 🚀"),
                                            backgroundColor: Color(0xFFFBBF24),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildBrandingSection(isLargeScreen),
                                  const SizedBox(height: 48),
                                  LoginForm(
                                    onLoginSuccess: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text("Login Successful! 🚀"),
                                          backgroundColor: Color(0xFFFBBF24),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandingSection(bool isLargeScreen) {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.5, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _fadeController,
            curve: Curves.easeOut,
          ),
        ),
        child: Column(
          crossAxisAlignment: isLargeScreen
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo and Brand Name
            AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + 0.2 * _fadeController.value,
                  child: child,
                );
              },
              child: Column(
                crossAxisAlignment: isLargeScreen
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Text(
                    "ANCAP",
                    textAlign:
                        isLargeScreen ? TextAlign.left : TextAlign.center,
                    style: TextStyle(
                      fontSize: isLargeScreen ? 96 : 72, // text-6xl lg:text-8xl
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.92, // letterSpacing: '0.02em'
                      height: 1,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Color(0xFFFBBF24),
                          blurRadius: 10,
                        ),
                        Shadow(
                          color: Color(0xFFFBBF24),
                          blurRadius: 20,
                          offset: Offset(0, 0),
                        ),
                        Shadow(
                          color: Color(0xFFFBBF24),
                          blurRadius: 30,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 64,
                    height: 4,
                    margin: isLargeScreen
                        ? null
                        : const EdgeInsets.symmetric(horizontal: 0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFBBF24),
                          Color(0xFFEAB308),
                        ], // yellow-400 to yellow-500
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFFFBBF24),
                          blurRadius: 20,
                        ),
                        BoxShadow(
                          color: Color(0xFFFBBF24),
                          blurRadius: 40,
                          offset: Offset(0, 0),
                        ),
                        BoxShadow(
                          color: Color(0xFFFBBF24),
                          blurRadius: 60,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Subtitle and Description
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _fadeController,
                curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _fadeController,
                    curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isLargeScreen
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Next-Generation Business Intelligence",
                      textAlign:
                          isLargeScreen ? TextAlign.left : TextAlign.center,
                      style: TextStyle(
                        fontSize:
                            isLargeScreen ? 30 : 24, // text-2xl lg:text-3xl
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFAFAFA), // text-foreground
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: BoxDecoration.lerp(
                                null,
                                isLargeScreen ? null : const BoxDecoration(),
                                1,
                              ) !=
                              null
                          ? const BoxConstraints(maxWidth: 448)
                          : null, // max-w-md
                      child: Text(
                        "Harness the power of AI to unlock insights from your business data. "
                        "Chat with your tables, get instant analytics, and make data-driven decisions.",
                        textAlign:
                            isLargeScreen ? TextAlign.left : TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18, // text-lg
                          color: Color(0xFFA1A1AA), // text-muted-foreground
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Feature Indicators
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _fadeController,
                curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
              ),
              child: Wrap(
                alignment:
                    isLargeScreen ? WrapAlignment.start : WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildFeatureIndicator(
                    color: const Color(0xFF4ADE80), // green-400
                    label: "AI-Powered Analytics",
                  ),
                  _buildFeatureIndicator(
                    color: const Color(0xFF71717A), // zinc-400
                    label: "Real-time Insights",
                  ),
                  _buildFeatureIndicator(
                    color: const Color(0xFFFBBF24), // yellow-400
                    label: "Natural Language Queries",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureIndicator({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(
                      0.5 +
                          0.3 * math.sin(_pulseController.value * 2 * math.pi),
                    ),
                    blurRadius:
                        4 + 2 * math.sin(_pulseController.value * 2 * math.pi),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFFA1A1AA), // text-muted-foreground
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingOrb({
    required AnimationController controller,
    double? left,
    double? top,
    double? right,
    double? bottom,
    required double size,
    required List<Color> colors,
    required double xOffset,
    required double yOffset,
    double delay = 0.0,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          final phase = (value * 2 * math.pi) + (delay * math.pi / 4);

          return Transform.translate(
            offset: Offset(
              xOffset * math.sin(phase) * 0.5,
              yOffset * math.sin(phase) * 0.5,
            ),
            child: child,
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: colors,
            ),
            boxShadow: [
              BoxShadow(
                color: colors[0],
                blurRadius: size * 0.5,
                spreadRadius: -size * 0.1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingOrb({required AnimationController controller}) {
    return Positioned.fill(
      child: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final scale = 1.0 + 0.2 * math.sin(controller.value * 2 * math.pi);
            final rotation = controller.value * 2 * math.pi;

            return Transform.scale(
              scale: scale,
              child: Transform.rotate(
                angle: rotation,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFBBF24)
                            .withOpacity(0.1), // yellow-400/10
                        const Color(0xFF71717A).withOpacity(0.1), // zinc-400/10
                        Colors.transparent,
                      ],
                      stops: const [0.2, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAiGrid() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            50 * (_pulseController.value % 1),
            50 * (_pulseController.value % 1),
          ),
          child: CustomPaint(
            painter: AiGridPainter(),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class AiGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFFFBBF24).withOpacity(0.1) // yellow-400 with opacity
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final cellSize = 50.0;
    final xCount = (size.width / cellSize).ceil() + 2;
    final yCount = (size.height / cellSize).ceil() + 2;

    // Draw horizontal lines
    for (int i = -1; i < yCount; i++) {
      final y = i * cellSize;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw vertical lines
    for (int i = -1; i < xCount; i++) {
      final x = i * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
