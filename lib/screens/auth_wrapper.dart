import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app/screens/login_screen.dart';
import 'package:first_app/screens/vital_screen.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (rememberMe && currentUser != null) {
      // "Remember me" was checked and Firebase session is still alive — go straight in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VitalsScreen()),
      );
    } else {
      // Either remember me was off, or no active session — sign out cleanly
      if (currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shown briefly while _resolve() runs
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
        ),
      ),
    );
  }
}