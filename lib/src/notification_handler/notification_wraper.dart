import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'notification_server.dart';


class NotificationWrapper extends StatefulWidget {
  final Widget child;

  const NotificationWrapper({super.key, required this.child});

  @override
  State<NotificationWrapper> createState() => _NotificationWrapperState();
}

class _NotificationWrapperState extends State<NotificationWrapper> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();

    _setupNotificationListeners();
  }



  void _setupNotificationListeners() {
    // Foreground messages
    // FirebaseMessaging.onMessage.listen((message) {
    //   _notificationService.handleForegroundMessage(message);
    // });
    //
    // // Background messages
    // FirebaseMessaging.onMessageOpenedApp.listen((message) {
    //   _notificationService.handleBackgroundMessage(message);
    // });
    //
    // // Terminated state messages
    // FirebaseMessaging.instance.getInitialMessage().then((message) {
    //   if (message != null) {
    //     _notificationService.handleBackgroundMessage(message);
    //   }
    // });
   }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}