import 'package:eleeye/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eleeye/screens/bottom_nav_bar.dart';
import 'package:eleeye/themes/theme_provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final authService = AuthScreen(); // Use an actual AuthService

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentEmail = authService.getCurrentUserEmail() ?? "Unknown";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome"),
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
                  MaterialPageRoute(
                    builder: (context) => const BottomNavBar(), // No need to pass theme manually
                  ),
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
