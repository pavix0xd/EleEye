import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const SettingsScreen({super.key, required this.onThemeChanged, required this.isDarkMode});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void _toggleTheme(bool value) {
    widget.onThemeChanged(value);
    setState(() {
      _isDarkMode = value;
    });
  }

  Future<void> _logOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Column(
        children: [
          ListTile(
            title: const Text("Dark Mode"),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: _toggleTheme,
              activeColor: Colors.teal.shade900,
              activeTrackColor: Colors.teal.shade700,
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text("Logout"),
            leading: const Icon(Icons.logout, color: Colors.red),
            onTap: _logOut,
          ),
        ],
      ),
    );
  }
}
