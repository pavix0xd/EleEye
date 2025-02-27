import 'package:eleeye/screens/login_screen.dart';
import 'package:eleeye/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      // Listen to auth state changes
      stream: Supabase.instance.client.auth.onAuthStateChange,

      // Build appropriate page based on auth state
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Extract session correctly from snapshot
        final session = snapshot.data?.session;

        // If there is a valid session, show MapPage
        if (session != null) {
          return MapPage();
        } else {
          // If there is no valid session, show LoginScreen
          return const LoginScreen();
        }
      },
    );
  }
}
