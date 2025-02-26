import 'package:flutter/material.dart';
import 'location_screen.dart';
import 'message_screen.dart';
import 'community_screen.dart';
import 'settings_screen.dart';
import 'map_screen.dart'; 

class BottomNavBar extends StatefulWidget {
  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    LocationScreen(),
    MessageScreen(),
    MyApp(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
  if (_selectedIndex != 0) {
    setState(() {
      _selectedIndex = 0; // Reset to Location tab
    });
    return false; // Prevent default back action
  } else {
    // If already on the first tab, go back to MapPage
    Navigator.pop(context);
    return false; // Prevents default back action
  }
}

  Widget _buildSelectedIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 31, 86, 50),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white),
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
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
            backgroundColor: Colors.white,
            selectedItemColor: const Color.fromARGB(255, 31, 86, 50),
            unselectedItemColor: Colors.grey,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(
                icon: _selectedIndex == 0
                    ? _buildSelectedIcon(Icons.location_on)
                    : const Icon(Icons.location_on),
                label: 'Location',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 1
                    ? _buildSelectedIcon(Icons.mail)
                    : const Icon(Icons.mail),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 2
                    ? _buildSelectedIcon(Icons.groups)
                    : const Icon(Icons.groups),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 3
                    ? _buildSelectedIcon(Icons.settings)
                    : const Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
