import 'package:eleeye/screens/auth_screen.dart';
import 'package:eleeye/screens/help.dart';
import 'package:eleeye/screens/upload_page.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_screen.dart';
import '../themes/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _generalNotifications = true;
  bool _updateNotifications = true;
  bool _securityNotifications = true; // Always ON
  String? _profileImageUrl;
  String _appVersion = "Loading...";
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
    _fetchProfileImage();
    _fetchAppVersion();
  }

  Future<void> _fetchProfileImage() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final response =
        await supabase.from('profiles').select('avatar_url').eq('id', userId).single();

    if (mounted) {
      setState(() {
        _profileImageUrl = response['avatar_url'];
      });
    }
  }

  Future<void> _fetchAppVersion() async {
  try {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = "Version ${packageInfo.version} (Build ${packageInfo.buildNumber})";
      });
    }
  } catch (e) {
    print("Error fetching app version: $e");
    if (mounted) {
      setState(() {
        _appVersion = "Unknown Version";
      });
    }
  }
}


  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _generalNotifications = prefs.getBool("general_notifications") ?? true;
      _updateNotifications = prefs.getBool("update_notifications") ?? true;
      _securityNotifications = true;
    });
  }

  Future<void> _toggleNotification(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == "general_notifications") _generalNotifications = value;
      if (key == "update_notifications") _updateNotifications = value;
    });
  }

  Future<void> _goToUploadPage() async {
    final updatedImageUrl = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UploadPage()),
    );

    if (updatedImageUrl != null && mounted) {
      setState(() {
        _profileImageUrl = updatedImageUrl;
      });
    }
  }

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

  Future<void> _showTurnOffNotificationsWarningDialog(String prefKey) async {
    return await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Turn Off Notifications"),
        content: const Text("Turning off notifications may affect your experience. Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _toggleNotification(prefKey, false);
              Navigator.pop(context);
            },
            child: const Text("Turn Off", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = AuthScreen();
    final currentEmail = authService.getCurrentUserEmail();

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          _buildProfileSection(currentEmail),
          _buildDarkModeToggle(themeProvider),
          _buildNotificationToggle("General Notifications", Icons.notifications_active, _generalNotifications, "general_notifications"),
          _buildNotificationToggle("App Updates", Icons.system_update, _updateNotifications, "update_notifications"),
          _buildSecurityNotificationToggle(),
          const Divider(),
          _buildHelpSupportTile(),
          _buildAppInfoTile(),
          const Divider(),
          _buildLogoutTile(context),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String email) {
    return ListTile(
      leading: GestureDetector(
        onTap: _goToUploadPage,
        child: CircleAvatar(
          radius: 30,
          backgroundImage: _profileImageUrl != null
              ? NetworkImage(_profileImageUrl!)
              : null,
          child: _profileImageUrl == null
              ? const Icon(Icons.person, size: 30)
              : null,
        ),
      ),
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
        },
        activeColor: Colors.teal.shade900,
        activeTrackColor: Colors.teal.shade700,
      ),
    );
  }

  Widget _buildNotificationToggle(String title, IconData icon, bool value, String prefKey) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: (newValue) {
          if (prefKey == "general_notifications" && !newValue) {
            _showTurnOffNotificationsWarningDialog(prefKey);
          } else {
            _toggleNotification(prefKey, newValue);
          }
        },
        activeColor: Colors.teal.shade900,
        activeTrackColor: Colors.teal.shade700,
      ),
    );
  }

  Widget _buildSecurityNotificationToggle() {
    return ListTile(
      leading: const Icon(Icons.verified_user, color: Colors.teal),
      title: const Text("Security Alerts (Always ON)"),
    );
  }

  Widget _buildHelpSupportTile() {
    return ListTile(
      leading: const Icon(Icons.help_outline, color: Colors.green),
      title: const Text("Help & Support"),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
        );
      },
    );
  }

  Widget _buildAppInfoTile() {
    return ListTile(
      leading: const Icon(Icons.info_outline, color: Colors.orange),
      title: const Text("App Info"),
      subtitle: Text(_appVersion), // Dynamically fetched version
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
