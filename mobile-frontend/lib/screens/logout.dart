import 'package:demo/screens/login_screen.dart';
import 'package:demo/screens/map_screen.dart';
import 'package:flutter/material.dart';

class LogoutScreen extends StatefulWidget {
  const LogoutScreen({Key? key}) : super(key: key);

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  final String? userEmail = "user@example.com"; // Replace with actual user data if needed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(userEmail != null ? 'Signed in as $userEmail' : 'User is not signed in'),
            MaterialButton(
              onPressed: () {
                // Handle sign-out logic here
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      showSignUpScreen: () {},
                    ),
                  ),
                );
              },
              color: Colors.teal.shade900,
              child: Text(
                'Sign out',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 20), 
            MaterialButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPage(), // Navigate to the map screen
                  ),
                );
              },
              color: Colors.teal.shade900, 
              child: Text(
                'Go to Next Screen',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
