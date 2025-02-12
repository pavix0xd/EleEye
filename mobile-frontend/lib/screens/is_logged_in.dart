import 'package:demo/screens/auth_screen.dart';
import 'package:demo/screens/logout.dart';
import 'package:flutter/material.dart';

class IsLoggedIn extends StatefulWidget {
  const IsLoggedIn({Key? key}) : super(key: key);

  @override
  _IsLoggedInState createState() => _IsLoggedInState();
}

class _IsLoggedInState extends State<IsLoggedIn> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Simulating login state, modify this logic as needed
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isLoggedIn = false; // Change this to `true` if user is logged in
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoggedIn ? LogoutScreen() : AuthScreen(),
    );
  }
}
