import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For environment variables
import 'dart:async';

import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load();
    
    final String? supabaseUrl = dotenv.env['SUPABASE_URL'];
    final String? supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception("Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env file.");
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    debugPrint("Error initializing Supabase: $e");
    return; // Exit early if Supabase initialization fails
  }

  runApp(EleEYEApp());
}


class EleEYEApp extends StatefulWidget {
  @override
  _EleEYEAppState createState() => _EleEYEAppState();
}

class _EleEYEAppState extends State<EleEYEApp> {
  StreamSubscription? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EleEYE App',
      home: SplashScreen(),
    );
  }
}
