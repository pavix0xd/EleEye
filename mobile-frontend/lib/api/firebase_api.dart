import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:eleeye/main.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  // Function to initialize notifications
  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final FCMToken = await _firebaseMessaging.getToken();
    print("FCM Token: $FCMToken");
    initPushNotifications();
  }

  // Function to handle received notifications
  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    // Navigate to the notification screen when the user taps the notification
    navigatorKey.currentState?.pushNamed('/message_screen', arguments: message);
  }

  // Initialize and handle background settings
  Future<void> initPushNotifications() async {
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }
}
