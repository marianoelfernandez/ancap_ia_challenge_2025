import "dart:math" as math;

import "package:anc_app/src/features/auth/cubits/auth_cubit.dart";
import "package:flutter/material.dart";
import "dart:async";
import "package:google_fonts/google_fonts.dart";
import "package:anc_app/src/router/router.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class LoginForm extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final AuthCubit authCubit = AuthCubit();

  LoginForm({super.key, required this.onLoginSuccess});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _typingController;

  late Animation<double> _formAnimation;
  late Animation<double> _pulseAnimation;

  late Animation<double> _headerIconAnimation;
  late Animation<double> _headerTitleAnimation;
  late Animation<double> _headerSubtitleAnimation;
  late Animation<double> _emailFieldAnimation;
  late Animation<double> _passwordFieldAnimation;
  late Animation<double> _loginButtonAnimation;
  late Animation<double> _featuresAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _formAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _headerIconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.1, 0.25, curve: Curves.elasticOut),
      ),
    );

    _headerTitleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.2, 0.35, curve: Curves.easeOut),
      ),
    );

    _headerSubtitleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.3, 0.45, curve: Curves.easeOut),
      ),
    );

    _emailFieldAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.4, 0.55, curve: Curves.easeOut),
      ),
    );

    _passwordFieldAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.5, 0.65, curve: Curves.easeOut),
      ),
    );

    _loginButtonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.6, 0.75, curve: Curves.easeOut),
      ),
    );

    _featuresAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.7, 0.85, curve: Curves.easeOut),
      ),
    );

    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _slideController.forward();
    _pulseController.repeat(reverse: true);
    _typingController.repeat();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _typingController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Use the AuthCubit to sign in
    final authCubit = context.read<AuthCubit>();
    await authCubit.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.isAuthenticated) {
          // Navigate to splash screen on successful login
          context.goToAppRoute(AppRoute.splash);
          widget.onLoginSuccess();
        } else if (state.hasError) {
          // Show error message
          _showErrorSnackBar(state.redactedError);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return AnimatedBuilder(
            animation: _formAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - _formAnimation.value)),
                child: Opacity(
                  opacity: _formAnimation.value.clamp(0.0, 1.0),
                  child: Container(
                    constraints:
                        const BoxConstraints(maxWidth: 480, maxHeight: 590),
                    child: Stack(
                      children: [
                        ...List.generate(8, (index) => NeuralDot(index: index)),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A1F2E),
                                Color(0xFF0F1419),
                              ],
                            ),
                            border: Border.all(
                              width: 2,
                              color: Colors.transparent,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFFFFC107)
                                      .withValues(alpha: 0.1),
                                  Colors.transparent,
                                  const Color(0xFF1976D2)
                                      .withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: const Color(0xFF1344D6)
                                    .withValues(alpha: 0.9),
                                backgroundBlendMode: BlendMode.multiply,
                              ),
                              child: Column(
                                children: [
                                  _buildHeader(),
                                  const SizedBox(height: 24),
                                  _buildLoginForm(state),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo with staggered animation
        AnimatedBuilder(
          animation: _headerIconAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _headerIconAnimation.value,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFC107)
                              .withValues(alpha: _pulseAnimation.value),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: Color(0xFF0D47A1),
                      size: 32,
                    ),
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        AnimatedBuilder(
          animation: _headerTitleAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _headerTitleAnimation.value,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
                ).createShader(bounds),
                child: Text(
                  "ANC-APP",
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        AnimatedBuilder(
          animation: _headerSubtitleAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _headerSubtitleAnimation.value,
              child: const Text(
                "Ancap Natural Chat",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w200,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLoginForm(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedBuilder(
          animation: _emailFieldAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(-20 * (1 - _emailFieldAnimation.value), 0),
              child: Opacity(
                opacity: _emailFieldAnimation.value,
                child: _buildInputField(
                  label: "Correo Electrónico",
                  controller: _emailController,
                  hintText: "Ingrese su correo",
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _passwordFieldAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(-20 * (1 - _passwordFieldAnimation.value), 0),
              child: Opacity(
                opacity: _passwordFieldAnimation.value,
                child: _buildInputField(
                  label: "Contraseña",
                  controller: _passwordController,
                  hintText: "Ingrese su contraseña",
                  isPassword: true,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: _loginButtonAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - _loginButtonAnimation.value)),
              child: Opacity(
                opacity: _loginButtonAnimation.value,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC107).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: authState.isLoading ? null : _handleLogin,
                      child: Container(
                        alignment: Alignment.center,
                        child: authState.isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF0D47A1),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "Conectando a IA...",
                                    style: TextStyle(
                                      color: Color(0xFF0D47A1),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.flash_on,
                                    color: Color(0xFF0D47A1),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Acceder al Asistente IA",
                                    style: TextStyle(
                                      color: Color(0xFF0D47A1),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword && !_isPasswordVisible,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    return AnimatedBuilder(
      animation: _featuresAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _featuresAnimation.value,
          child: Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFeatureItem(
                    icon: Icons.psychology,
                    label: "Análisis Inteligente",
                    color: const Color(0xFF1976D2),
                  ),
                ),
                Expanded(
                  child: _buildFeatureItem(
                    icon: Icons.security,
                    label: "Acceso Seguro",
                    color: const Color(0xFFFFC107),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class NeuralDot extends StatefulWidget {
  final int index;

  const NeuralDot({super.key, required this.index});

  @override
  State<NeuralDot> createState() => _NeuralDotState();
}

class _NeuralDotState extends State<NeuralDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late double left;
  late double top;

  @override
  void initState() {
    super.initState();

    final random = math.Random(widget.index);
    left = random.nextDouble();
    top = random.nextDouble();

    _controller = AnimationController(
      duration: Duration(milliseconds: 2000 + random.nextInt(2000)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: left * 350,
          top: top * 300,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: (_opacityAnimation.value * 0.1).clamp(0.0, 1.0),
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFC107),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
