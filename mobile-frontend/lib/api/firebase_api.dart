import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:eleeye/main.dart'; // Ensure navigatorKey is correctly set up

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fcmToken = await _firebaseMessaging.getToken();
    print("FCM Token: $fcmToken");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground message received: ${message.notification?.title}");
    });

    initPushNotifications();
  }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    navigatorKey.currentState?.pushNamed(
      '/message_screen',
      arguments: message, // Pass the entire RemoteMessage
    );
  }

  Future<void> initPushNotifications() async {
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }
}
