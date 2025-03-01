import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NotificationScreen(),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<String> notifications = List.generate(
      10, (index) => "Elephant Sighting!\nLocation: 500m ahead on Buttala Road");

      
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
  leading: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () {
      Navigator.pop(context);
    },
  ),
  title: Text("Notifications"),
  backgroundColor: Colors.teal.shade900,
  actions: [
    IconButton(
      icon: Icon(Icons.delete, color: Colors.white), // Clear all button
      onPressed: () {
        setState(() {
          notifications.clear(); // Clears all notifications
        });
      },
    ),
  ],
),

      
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return Dismissible(
              key: Key(notifications[index]),
              onDismissed: (direction) {
                setState(() {
                  notifications.removeAt(index);
                });
              },
              background: Container(color: Colors.red),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(
                    "Elephant Sighting!",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("2 minutes ago\nLocation: 500m ahead on Buttala Road"),
                  trailing: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        notifications.removeAt(index);
                      });
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.location_on), label: "Map"),
          BottomNavigationBarItem(
              icon: Icon(Icons.email), label: "Notifications"),
          BottomNavigationBarItem(
              icon: Icon(Icons.group), label: "Community"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
        currentIndex: 1,
        selectedItemColor: Colors.teal.shade900,
      ),
    );
  }
}
