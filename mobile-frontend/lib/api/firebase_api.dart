import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eleeye/main.dart';

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    
    final fcmToken = await _firebaseMessaging.getToken();
    print("FCM Token: $fcmToken");

    if (fcmToken != null) {
      await saveTokenToSupabase(fcmToken);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground message received: ${message.notification?.title}");
    });

    initPushNotifications();
  }

  Future<void> saveTokenToSupabase(String token) async {
  final user = _supabase.auth.currentUser;
  if (user == null) return;

  try {
    await _supabase.from('userInfo').upsert({
      'id': user.id,  
      'fcm_token': token,
      'created_at': DateTime.now().toIso8601String(),
    });

    print("FCM token registered to Supabase!");
  } catch (e) {
    print("Error saving FCM token: $e");
  }
}


  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
    navigatorKey.currentState?.pushNamed(
      '/message_screen',
      arguments: message,
    );
  }

  Future<void> initPushNotifications() async {
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToSupabase);
  }
}
