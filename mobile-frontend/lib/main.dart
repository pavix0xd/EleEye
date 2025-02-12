import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure that the Flutter app is initialized

  runApp(EleEYEApp());
}

class EleEYEApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EleEYE App',
      home: SplashScreen(), // Start with SplashScreen
    );
  }
}