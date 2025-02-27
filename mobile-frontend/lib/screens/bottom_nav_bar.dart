import 'package:flutter/material.dart';
import '../screens/location_screen.dart';
import '../screens/message_screen.dart';
import '../screens/community_screen.dart';
import '../screens/settings_screen.dart';

class BottomNavBar extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const BottomNavBar({Key? key, required this.isDarkMode, required this.onThemeChanged}) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      LocationScreen(),
      MessageScreen(),
      CommunityScreen(),
      SettingsScreen(isDarkMode: widget.isDarkMode, onThemeChanged: widget.onThemeChanged),
    ];
  }

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

  Widget _buildSelectedIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.white : const Color.fromARGB(255, 31, 86, 50),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: widget.isDarkMode ? Colors.black : Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode ? Colors.black : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
            selectedItemColor: widget.isDarkMode ? Colors.white : const Color.fromARGB(255, 31, 86, 50),
            unselectedItemColor: widget.isDarkMode ? Colors.grey[500] : Colors.grey,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(
                icon: _selectedIndex == 0
                    ? _buildSelectedIcon(Icons.location_on)
                    : Icon(Icons.location_on, color: widget.isDarkMode ? Colors.white : Colors.black),
                label: 'Location',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 1
                    ? _buildSelectedIcon(Icons.mail)
                    : Icon(Icons.mail, color: widget.isDarkMode ? Colors.white : Colors.black),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 2
                    ? _buildSelectedIcon(Icons.groups)
                    : Icon(Icons.groups, color: widget.isDarkMode ? Colors.white : Colors.black),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 3
                    ? _buildSelectedIcon(Icons.settings)
                    : Icon(Icons.settings, color: widget.isDarkMode ? Colors.white : Colors.black),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
