import 'package:demo/screens/login_screen.dart';
import 'package:demo/screens/signup_screen.dart'; 
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Initially, show the login screen
  bool showLoginScreen = true;

  void toggleScreens() {
    setState(() {
      showLoginScreen = !showLoginScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginScreen) {
      return LoginScreen(showSignUpScreen: toggleScreens);
    } else {
      return SignupScreen(showLoginScreen: toggleScreens);
    }
  }
}
