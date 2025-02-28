import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationItem {
  final String title;
  final String description;
  final DateTime timestamp;

  NotificationItem({
    required this.title,
    required this.description,
    required this.timestamp,
  });
}

class MessageScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<MessageScreen> {
  List<NotificationItem> notifications = List.generate(
    10,
    (index) => NotificationItem(
      title: "Elephant Sighting!",
      description: "Location: 500m ahead on Buttala Road",
      timestamp: DateTime.now().subtract(Duration(minutes: index * 2)),
    ),
  );

  void _showUndoSnackbar(NotificationItem removedItem, int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Notification dismissed"),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () {
            setState(() {
              notifications.insert(index, removedItem);
            });
          },
          textColor: Colors.yellow,
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger( // Ensures the snackbar is properly managed
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("Notifications"),
          elevation: 0, // Removes shadow for a cleaner look
        ),
        body: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: notifications.isEmpty
              ? Center(child: Text("No Notifications"))
              : ListView.builder(
                  padding: const EdgeInsets.all(10.0),
                  physics: BouncingScrollPhysics(), // Makes scrolling smoother
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return Dismissible(
                      key: Key(notifications[index].timestamp.toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        NotificationItem removedItem = notifications[index];
                        setState(() {
                          notifications.removeAt(index);
                        });
                        _showUndoSnackbar(removedItem, index);
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      child: NotificationTile(
                        notification: notifications[index],
                        onRemove: () {
                          NotificationItem removedItem = notifications[index];
                          setState(() {
                            notifications.removeAt(index);
                          });
                          _showUndoSnackbar(removedItem, index);
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onRemove;

  const NotificationTile({required this.notification, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.warning, color: Colors.red),
        title: Text(
          notification.title,
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${timeago.format(notification.timestamp)}\n${notification.description}"),
        trailing: IconButton(
          icon: Icon(Icons.close),
          onPressed: onRemove,
        ),
        onTap: () {
          Fluttertoast.showToast(msg: "Opening Notification Details...");
        },
      ),
    );
  }
}
