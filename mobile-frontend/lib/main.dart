import 'package:eleeye/api/firebase_api.dart';
import 'package:eleeye/screens/login_screen.dart';
import 'package:eleeye/screens/message_screen.dart';
import 'package:eleeye/screens/splash_screen.dart';
import 'package:eleeye/screens/settings_screen.dart';
import 'package:eleeye/screens/bottom_nav_bar.dart';
import 'package:eleeye/themes/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

// Global navigator key for handling navigation from Firebase notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint("Firebase initialized successfully.");

    // Load environment variables
    await dotenv.load();
    final String? supabaseUrl = dotenv.env['SUPABASE_URL'];
    final String? supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception("Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env file.");
    }

    // Initialize Supabase
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    debugPrint("Supabase initialized successfully.");

    // Initialize Firebase notifications
    await FirebaseApi().initNotifications();
    debugPrint("Firebase Cloud Messaging (FCM) initialized.");
  } catch (e) {
    debugPrint("Error during initialization: $e");
    return;
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const EleEYEApp(),
    ),
  );
}

class EleEYEApp extends StatelessWidget {
  const EleEYEApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final session = Supabase.instance.client.auth.currentSession;

    debugPrint("🎨 Building UI with theme: ${themeProvider.isDarkMode ? 'Dark' : 'Light'}");

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EleEYE App',
      navigatorKey: navigatorKey, // Set navigatorKey for Firebase notifications
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: session != null ? const BottomNavBar() : const SplashScreen(),
      routes: {
        '/settings': (context) => SettingsScreen(),
        '/bottomNavBar': (context) => BottomNavBar(),
        '/login': (context) => const LoginScreen(),
        '/message_screen': (context) => const MessageScreen(),
      },
    );
  }
}
