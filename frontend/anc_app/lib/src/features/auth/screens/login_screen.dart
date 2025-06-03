import "package:flutter/material.dart";
import "dart:async";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  final Color primaryColor = const Color.fromARGB(255, 0, 5, 10);
  final Color accentColor = const Color.fromARGB(255, 255, 198, 0);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start the animation after a short delay
    Timer(const Duration(milliseconds: 200), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Logo and Title with Fade Animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // AI-like pulsing effect around the icon
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.5),
                                  spreadRadius: 5,
                                  blurRadius: 20,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF0077FF)
                                      .withOpacity(_pulseAnimation.value * 0.5),
                                  spreadRadius: 2 + (_pulseAnimation.value * 8),
                                  blurRadius: 10 + (_pulseAnimation.value * 15),
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: Icon(
                          Icons.chat_bubble_outline,
                          color: accentColor,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        "Ancap Chatbot",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: accentColor.withOpacity(0.3),
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40.0),
                // Email field with slide animation
                SlideTransition(
                  position: _slideAnimation,
                  child: SizedBox(
                    height: 44.0,
                    child: TextFormField(
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14.0),
                      decoration: InputDecoration(
                        hintText: "Email",
                        prefixIcon:
                            Icon(Icons.email, color: accentColor, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0, // Reduced vertical padding
                          horizontal: 12.0,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14.0,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                // Password field with slide animation
                SlideTransition(
                  position: _slideAnimation,
                  child: SizedBox(
                    height: 44.0,
                    child: TextFormField(
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14.0),
                      decoration: InputDecoration(
                        hintText: "Password",
                        prefixIcon:
                            Icon(Icons.lock, color: accentColor, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0, // Reduced vertical padding
                          horizontal: 12.0,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14.0,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      obscureText: true,
                    ),
                  ),
                ),
                const SizedBox(height: 30.0),
                // Login button with animation
                SlideTransition(
                  position: _slideAnimation,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0077FF)
                                  .withOpacity(_pulseAnimation.value * 0.3),
                              spreadRadius: 1,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF0077FF,
                        ), // Changed from yellow to blue
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        elevation: 2,
                        shadowColor: const Color(0xFF0077FF).withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        // Handle login logic here
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
