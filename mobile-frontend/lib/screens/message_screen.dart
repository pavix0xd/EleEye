import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timeago/timeago.dart' as timeago;

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  List<NotificationItem> notifications = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Retrieve message passed through navigation
    final RemoteMessage? message = ModalRoute.of(context)?.settings.arguments as RemoteMessage?;

    if (message != null) 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: notifications.isEmpty
          ? Center(child: Text("No Notifications"))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return NotificationTile(notification: notifications[index]);
              },
            ),
    );
  }
}

class NotificationItem {
  final String title;
  final String description;
  final DateTime timestamp;

  NotificationItem({required this.title, required this.description, required this.timestamp});
}

class NotificationTile extends StatelessWidget {
  final NotificationItem notification;

  const NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(notification.title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${timeago.format(notification.timestamp)}\n${notification.description}"),
      ),
    );
  }
}
