import 'package:demo/screens/auth_screen.dart';
import 'package:flutter/material.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  //get auth service
  final authService = AuthScreen();

  //logout button pressed
  void logOut()async{
    await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {

    // temporary thing: return logged user email.
    final currentEmail = authService.getCurrentUserEmail();

    return Scaffold(
      appBar: AppBar(title: const Text("Map"),
      actions: [
        //logout button
        IconButton(
          onPressed: logOut,
          icon: const Icon(Icons.logout),
        )
      ],),
      body: Center(
        child: Text("Logged in as: $currentEmail"),
      )
    );
  }
}