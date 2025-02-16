import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BottomNavBar(),
    );
  }
}

class BottomNavBar extends StatefulWidget {
  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0; // Default selected index (Location)

  // List of pages to navigate to when an icon is selected
  final List<Widget> _pages = [
    LocationScreen(),
    MessagesScreen(),
    CommunityScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
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
                  : Icon(Icons.location_on),
              label: 'Location',
            ),
            BottomNavigationBarItem(
              icon: _selectedIndex == 1
                  ? _buildSelectedIcon(Icons.mail)
                  : Icon(Icons.mail),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: _selectedIndex == 2
                  ? _buildSelectedIcon(Icons.groups)
                  : Icon(Icons.groups),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: _selectedIndex == 3
                  ? _buildSelectedIcon(Icons.settings)
                  : Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedIcon(IconData icon) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 31, 86, 50),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}
