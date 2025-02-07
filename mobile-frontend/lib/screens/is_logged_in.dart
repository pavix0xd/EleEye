import 'package:demo/screens/auth_screen.dart';
import 'package:demo/screens/logout.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class IsLoggedIn extends StatelessWidget {
  const IsLoggedIn({Key? key}) : super(key: key); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return LogoutScreen(); 
          } else {
            return AuthScreen(); 
          }
        },
      ),
    );
  }
}
