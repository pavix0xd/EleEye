import 'package:flutter/material.dart';
import './message_screen.dart';


class LocationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Location")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MessageScreen()),
            );
          },
          child: Text("Go to Inner Screen"),
        ),
      ),
    );
  }
}
