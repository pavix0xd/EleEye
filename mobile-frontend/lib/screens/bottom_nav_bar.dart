import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/location_screen.dart';
import '../screens/message_screen.dart';
import '../screens/community_screen.dart';
import '../screens/settings_screen.dart';
import '../themes/theme_provider.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

<<<<<<< HEAD
  final List<Widget> _pages = [
    LocationScreen(),
    MessageScreen(),
    MyApp(),
    SettingsScreen(),
  ];
=======
  List<Widget> get _pages => [
         LocationScreen(),
         MessageScreen(),
         CommunityScreen(),
         SettingsScreen(),
      ];
>>>>>>> main

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    } else {
      Navigator.pop(context);
      return false;
    }
  }

  Widget _buildSelectedIcon(IconData icon, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white : const Color.fromARGB(255, 31, 86, 50),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: isDarkMode ? Colors.black : Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            selectedItemColor: isDarkMode ? Colors.white : const Color.fromARGB(255, 31, 86, 50),
            unselectedItemColor: isDarkMode ? Colors.grey[500] : Colors.grey,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(
                icon: _selectedIndex == 0
                    ? _buildSelectedIcon(Icons.location_on, isDarkMode)
                    : Icon(Icons.location_on, color: isDarkMode ? Colors.white : Colors.black),
                label: 'Location',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 1
                    ? _buildSelectedIcon(Icons.mail, isDarkMode)
                    : Icon(Icons.mail, color: isDarkMode ? Colors.white : Colors.black),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 2
                    ? _buildSelectedIcon(Icons.groups, isDarkMode)
                    : Icon(Icons.groups, color: isDarkMode ? Colors.white : Colors.black),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 3
                    ? _buildSelectedIcon(Icons.settings, isDarkMode)
                    : Icon(Icons.settings, color: isDarkMode ? Colors.white : Colors.black),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
