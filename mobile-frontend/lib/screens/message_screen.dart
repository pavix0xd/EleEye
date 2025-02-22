import 'package:flutter/material.dart';
import 'community_screen.dart';

class MessageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Message")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CommunityScreen()),
            );
          },
          child: Text("Go to Inner Screen"),
        ),
      ),
    );
  }
}
