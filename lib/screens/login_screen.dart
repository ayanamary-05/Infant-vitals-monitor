import 'package:flutter/material.dart';
import 'package:first_app/screens/vital_screen.dart';

// ─────────────────────────────────────────
// LOGIN SCREEN
// ─────────────────────────────────────────
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  /// Slide-up page route used to open SignUpScreen
  Route _slideUpRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0); // starts from bottom
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background image ──────────────────────
          SizedBox.expand(
            child: Image.asset(
              "assets/images/login_bg2.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // ── Dark overlay ──────────────────────────
          Container(
            color: Colors.black.withValues(alpha: 0.55),
          ),

          // ── Login UI ──────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Logo + App name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: Image.asset(
                          "assets/images/logo.png",
                          height: 74,
                          width: 74,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        "NeoBeat",
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Peace of mind, one breath at a time.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Color.fromARGB(179, 255, 255, 255),
                      letterSpacing: 0.3,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── LOG IN button (green / primary) ──
                  _PillButton(
                    label: "LOG IN",
                    backgroundColor: const Color(0xFF1DB954), // Spotify green
                    foregroundColor: Colors.white,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VitalsScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── SIGN UP button (dark / secondary) ──
                  _PillButton(
                    label: "SIGN UP",
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                    borderColor: Colors.white38,
                    onPressed: () {
                      Navigator.push(
                        context,
                        _slideUpRoute(const SignUpScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// SIGN UP SCREEN  (slides up from bottom)
// ─────────────────────────────────────────
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background image ──────────────────────
          SizedBox.expand(
            child: Image.asset(
              "assets/images/signup_bg.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // ── Darker overlay for sign-up ────────────
          Container(
            color: Colors.black.withValues(alpha: 0.68),
          ),

          // ── Sign-up UI ────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white, size: 32),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title
                        const Text(
                          "SIGN UP",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Monitor your infant's vitals with ease.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),

                        const SizedBox(height: 36),

                        // ── Email field ───────────────────
                        _GlassTextField(hintText: "email address"),

                        const SizedBox(height: 16),

                        // ── Password field ────────────────
                        _GlassTextField(
                            hintText: "password", obscureText: true),

                        const SizedBox(height: 32),

                        // ── CREATE ACCOUNT button ─────────
                        _PillButton(
                          label: "CREATE ACCOUNT",
                          backgroundColor: const Color(0xFF1DB954),
                          foregroundColor: Colors.white,
                          onPressed: () {
                            // TODO: handle account creation
                          },
                          width: 230,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────

/// Rounded pill-shaped button used on both screens
class _PillButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback onPressed;
  final double? width;

  const _PillButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.borderColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 1.8,
          ),
        ),
      ),
    );
  }
}

/// Semi-transparent text field used on the sign-up screen
class _GlassTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;

  const _GlassTextField({
    required this.hintText,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1DB954), width: 1.5),
        ),
      ),
    );
  }
}