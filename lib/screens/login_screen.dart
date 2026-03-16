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
      transitionDuration: const Duration(milliseconds: 520),
      reverseTransitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0); // starts from bottom
        const end = Offset.zero;
        const curve = Curves.easeInOutQuart;
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

                  // ── LOGIN button (green / primary) ──
                  _PillButton(
                    label: "LOGIN",
                    backgroundColor: const Color(0xFF1DB954), // Spotify green
                    foregroundColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        _slideUpRoute(const LoginFormScreen()),
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
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordObscured = true;
  bool _confirmPasswordObscured = true;
  String? _passwordError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePasswords() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    setState(() {
      if (confirmPassword.isEmpty || password.isEmpty) {
        _passwordError = null;
        return;
      }
      _passwordError = password == confirmPassword
          ? null
          : "Passwords do not match";
    });
  }

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
                          "Because every beat counts.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── First name field ──────────────
                        _GlassTextField(
                          hintText: "first name",
                          controller: _firstNameController,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 16),

                        // ── Last name field ───────────────
                        _GlassTextField(
                          hintText: "last name",
                          controller: _lastNameController,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 16),

                        // ── Email field ───────────────────
                        _GlassTextField(
                          hintText: "email address",
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 16),

                        // ── Password field ────────────────
                        _GlassTextField(
                          hintText: "password",
                          controller: _passwordController,
                          obscureText: _passwordObscured,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => _validatePasswords(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordObscured = !_passwordObscured;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Confirm password field ─────────
                        _GlassTextField(
                          hintText: "confirm password",
                          controller: _confirmPasswordController,
                          obscureText: _confirmPasswordObscured,
                          textInputAction: TextInputAction.done,
                          errorText: _passwordError,
                          onChanged: (_) => _validatePasswords(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _confirmPasswordObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _confirmPasswordObscured =
                                    !_confirmPasswordObscured;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── CREATE ACCOUNT button ─────────
                        _PillButton(
                          label: "CREATE ACCOUNT",
                          backgroundColor: const Color(0xFF1DB954),
                          foregroundColor: Colors.white,
                          onPressed: () {
                            _validatePasswords();
                            if (_passwordError != null) {
                              return;
                            }
                            // TODO: handle account creation
                          },
                          width: 230,
                        ),

                        const SizedBox(height: 14),

                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            const Text(
                              "Already have an account? ",
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration:
                                        const Duration(milliseconds: 520),
                                    reverseTransitionDuration:
                                        const Duration(milliseconds: 420),
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        const LoginFormScreen(),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = Offset(0.0, 1.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOutQuart;
                                      final tween = Tween(
                                              begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));
                                      return SlideTransition(
                                        position: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontStyle: FontStyle.italic,
                                  decoration: TextDecoration.underline,
                                  decorationStyle: TextDecorationStyle.dotted,
                                ),
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
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const _GlassTextField({
    required this.hintText,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
    this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        errorText: errorText,
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
        suffixIcon: suffixIcon,
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

// ─────────────────────────────────────────
// LOGIN FORM SCREEN  (slides up from bottom)
// ─────────────────────────────────────────
class LoginFormScreen extends StatefulWidget {
  const LoginFormScreen({super.key});

  @override
  State<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background image ──────────────────────
          SizedBox.expand(
            child: Image.asset(
              "assets/images/login_bg3.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // ── Dark overlay ──────────────────────────
          Container(
            color: Colors.black.withValues(alpha: 0.68),
          ),

          // ── Login UI ──────────────────────────────
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
                        const Text(
                          "LOGIN",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Watching over what matters the most.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── Email field ───────────────────
                        _GlassTextField(
                          hintText: "email address",
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 16),

                        // ── Password field ────────────────
                        _GlassTextField(
                          hintText: "password",
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                checkColor: Colors.black,
                                fillColor: MaterialStateProperty.resolveWith(
                                  (states) {
                                    if (states.contains(MaterialState.selected)) {
                                      return const Color(0xFF1DB954);
                                    }
                                    return Colors.white24;
                                  },
                                ),
                                side: const BorderSide(color: Colors.white54),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Remember me",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                // TODO: handle forgot password
                              },
                              child: const Text(
                                "Forgot password?",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                  decorationStyle: TextDecorationStyle.dotted,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // ── LOGIN button ─────────────────
                        _PillButton(
                          label: "LOGIN",
                          backgroundColor: const Color(0xFF1DB954),
                          foregroundColor: Colors.white,
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VitalsScreen(),
                              ),
                            );
                          },
                          width: 230,
                        ),

                        const SizedBox(height: 14),

                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration:
                                        const Duration(milliseconds: 520),
                                    reverseTransitionDuration:
                                        const Duration(milliseconds: 420),
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        const SignUpScreen(),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = Offset(0.0, 1.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOutQuart;
                                      final tween = Tween(
                                              begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));
                                      return SlideTransition(
                                        position: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                              child: const Text(
                                "Sign up",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontStyle: FontStyle.italic,
                                  decoration: TextDecoration.underline,
                                  decorationStyle: TextDecorationStyle.dotted,
                                ),
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
        ],
      ),
    );
  }
}