import 'package:demo/screens/auth_screen.dart';
import 'package:demo/screens/login_screen.dart';
import 'package:flutter/material.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Get auth service
  final authService = AuthScreen();

  // Logout button pressed
  void logOut() async {
    await authService.signOut();
    
    // Redirect user back to login page
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // Removes all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Temporary: return logged-in user's email.
    final currentEmail = authService.getCurrentUserEmail();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Map"),
        actions: [
          // Logout button
          IconButton(
            onPressed: logOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Text("Logged in as: $currentEmail"),
      ),
    );
  }
}
