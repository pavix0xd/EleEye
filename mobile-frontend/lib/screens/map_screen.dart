import 'package:flutter/material.dart';
import 'package:demo/screens/auth_screen.dart';
import 'package:demo/screens/login_screen.dart';
import 'package:demo/screens/bottom_nav_bar.dart'; 

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final authService = AuthScreen();

  // Logout function
  Future<void> logOut() async {
    await authService.signOut(); // Ensure sign-out completes

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // Removes all previous routes from stack
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = authService.getCurrentUserEmail();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Map"),
        actions: [
          IconButton(
            onPressed: logOut, // Correctly calling the logout function
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Logged in as: $currentEmail"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => BottomNavBar()),
                );
              },
              child: const Text("Go to Main App"),
            ),
          ],
        ),
      ),
    );
  }
}
