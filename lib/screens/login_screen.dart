import 'package:first_app/screens/vital_screen.dart';
import 'package:flutter/material.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  body: Stack(
    children: [

      /// Background image
      SizedBox.expand(
        child: Image.asset(
          "assets/images/login_bg2.jpg",
          fit: BoxFit.cover,
        ),
      ),

      /// Dark overlay
      Container(
        color: Colors.black.withValues(alpha: 0.5),
      ),

      /// Login UI
      Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/logo.png",
                    height: 40,
                  ), //App logo
                  const SizedBox(width: 12),
                ],
              ),

              const Text(
                "Infant Vitals Monitor",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              /// Email
              TextField(
                decoration: InputDecoration(
                  hintText: "Email",
                  filled: true,
                  fillColor: const Color.fromARGB(0, 11, 0, 0).withValues(alpha: 0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Password
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                  filled: true,
                  fillColor: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VitalsScreen(),
                    ),
                  );
                },
                child: const Text("Login"),
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