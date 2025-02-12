import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter app is initialized

  await Supabase.initialize( // Initialize Supabase
    url: "https://ibdtjkzghhjqpbilmggt.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImliZHRqa3pnaGhqcXBiaWxtZ2d0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg5OTAwMTksImV4cCI6MjA1NDU2NjAxOX0.7isnrNBjOhpk05ktD3uhX0ycWi-0rL_cdaWoCzdFIfY",
  );

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
