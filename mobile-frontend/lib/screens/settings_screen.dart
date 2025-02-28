import 'package:eleeye/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_screen.dart';
import '../themes/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logOut(BuildContext context) async {
    final shouldLogout = await _showLogoutConfirmation(context);
    if (shouldLogout) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<bool> _showLogoutConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Logout"),
            content: const Text("Are you sure you want to log out?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Logout", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = AuthScreen(); 
    final currentEmail = authService.getCurrentUserEmail() ?? "Unknown";

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          _buildUserInfoTile(currentEmail),
          _buildDarkModeToggle(themeProvider),
          _buildLogoutTile(context),
        ],
      ),
    );
  }

  Widget _buildUserInfoTile(String email) {
    return ListTile(
      leading: const Icon(Icons.person, color: Colors.teal),
      title: const Text("Logged in as"),
      subtitle: Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDarkModeToggle(ThemeProvider themeProvider) {
    return ListTile(
      leading: const Icon(Icons.dark_mode, color: Colors.teal),
      title: const Text("Dark Mode"),
      trailing: Switch(
        value: themeProvider.isDarkMode,
        onChanged: (value) {
          themeProvider.toggleTheme(value);
          debugPrint("Settings screen theme toggled: $value");
        },
        activeColor: Colors.teal.shade900,
        activeTrackColor: Colors.teal.shade700,
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text("Logout"),
      onTap: () => _logOut(context),
    );
  }
}
