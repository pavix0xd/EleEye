import 'package:eleeye/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/bottom_nav_bar.dart';
import 'firebase_options.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
    return;
  }

  runApp(const EleEYEApp());
}

class EleEYEApp extends StatefulWidget {
  const EleEYEApp({super.key});

  @override
  _EleEYEAppState createState() => _EleEYEAppState();
}

class _EleEYEAppState extends State<EleEYEApp> {
  bool _isDarkMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _navigateToLogin(); // Navigate to the login screen after splash screen
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    setState(() {
      _isDarkMode = isDark;
    });
  }

  void _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3)); // 3-second splash delay
    setState(() {
      _isLoading = false;
    });

    // Navigate to the LoginScreen after splash
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EleEYE App',
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: _isLoading
          ? const SplashScreen()
          : const LoginScreen(), // Navigate to LoginScreen after splash
      routes: {
        '/settings': (context) => SettingsScreen(onThemeChanged: _toggleTheme, isDarkMode: _isDarkMode),
        '/bottomNavBar': (context) => BottomNavBar(isDarkMode: _isDarkMode, onThemeChanged: _toggleTheme),
      },
    );
  }
}
