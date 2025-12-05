import 'package:flutter/material.dart';
import 'package:eduthon/screens/login_screen.dart';
import 'package:eduthon/screens/auth/signup_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      onSignupTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SignupScreen(
              onLoginTap: () => Navigator.pop(context),
            ),
          ),
        );
      },
    );
  }
}
