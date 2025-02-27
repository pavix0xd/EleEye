import 'package:flutter/material.dart';
import 'package:demo/screens/auth_screen.dart';
import 'package:demo/screens/bottom_nav_bar.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final authService = AuthScreen();

  @override
  Widget build(BuildContext context) {
    final currentEmail = authService.getCurrentUserEmail();

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
                  MaterialPageRoute(builder: (context) => BottomNavBar(
                    isDarkMode: false, // or any appropriate value
                    onThemeChanged: (bool value) {
                      // handle theme change
                    },
                  )),
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
