import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app/screens/login_screen.dart';
import 'package:first_app/screens/admin_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFCF6679) : const Color(0xFF1DB954),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter admin credentials.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final snap = await FirebaseDatabase.instance.ref('users/$uid/role').get();
      final role = (snap.value as String?)?.toLowerCase();

      if (role == 'admin') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', 'admin');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        await FirebaseAuth.instance.signOut();
        _showSnackBar('Access Denied: Admin role required.');
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'Authentication failed.');
    } catch (e) {
      _showSnackBar('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset("assets/images/login_bg3.jpg", fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withValues(alpha: 0.75)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded, size: 80, color: Color(0xFF1DB954)),
                          const SizedBox(height: 16),
                          const Text(
                            "ADMIN LOGIN",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Authorized Access Only",
                            style: TextStyle(color: Colors.white60, fontSize: 14, fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 40),
                          // Using the public versions of the widgets from login_screen.dart
                          GlassTextField(
                            hintText: "admin email",
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          GlassTextField(
                            hintText: "password",
                            controller: _passwordController,
                            obscureText: _passwordObscured,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordObscured ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white70,
                              ),
                              onPressed: () => setState(() => _passwordObscured = !_passwordObscured),
                            ),
                          ),
                          const SizedBox(height: 40),
                          PillButton(
                            label: _isLoading ? "AUTHENTICATING..." : "ACCESS DASHBOARD",
                            backgroundColor: const Color(0xFF1DB954),
                            foregroundColor: Colors.white,
                            onPressed: _isLoading ? () {} : _login,
                            width: 260,
                          ),
                          const SizedBox(height: 20), // Prevent bottom overflow
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF1DB954)),
              ),
            ),
        ],
      ),
    );
  }
}
