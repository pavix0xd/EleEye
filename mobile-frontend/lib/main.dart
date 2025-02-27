import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/bottom_nav_bar.dart';
import 'firebase_options.dart';
import 'themes/theme_provider.dart';
import 'package:provider/provider.dart';

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

    debugPrint("Building UI with theme: ${themeProvider.isDarkMode ? 'Dark' : 'Light'}");

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EleEYE App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: SplashScreen(),
      routes: {
        '/settings': (context) => SettingsScreen(),
        '/bottomNavBar': (context) => BottomNavBar(),
      },
    );
  }
}
