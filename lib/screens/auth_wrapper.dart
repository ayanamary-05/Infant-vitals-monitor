import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app/screens/login_screen.dart';
import 'package:first_app/screens/home_screen.dart';
import 'package:first_app/screens/admin_dashboard.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('remember_me') ?? false;
      final currentUser = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      if (rememberMe && currentUser != null) {
        final snap = await FirebaseDatabase.instance
            .ref('users/${currentUser.uid}/role')
            .get()
            .timeout(const Duration(seconds: 10));

        final role = (snap.value as String?)?.toLowerCase() ?? 'parent';

        if (!mounted) return;

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        if (currentUser != null) {
          await FirebaseAuth.instance.signOut();
        }
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('AuthWrapper resolve error: $e');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}