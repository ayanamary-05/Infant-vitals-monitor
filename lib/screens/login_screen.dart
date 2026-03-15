import 'package:first_app/screens/vital_screen.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () 
              {
                Navigator.pushReplacement
                (
                  context,
                  MaterialPageRoute
                  (
                    builder: (context) => const VitalsScreen(),
                  ),
                );
            },
  child: const Text("Login"),
)
          ],
        ),
      ),
    );
  }
}