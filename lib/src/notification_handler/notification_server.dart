
import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  //Enable notification for this app
  void requestNotificationPermission() async{
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );
    if(settings.authorizationStatus== AuthorizationStatus.authorized){
      print('user granted permission');
    }else if (settings.authorizationStatus== AuthorizationStatus.provisional){
      print('user provisional granted permission');
    }else{
      SnackBar(
        content: Text('Notification permission denied, please allow notifications.'),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
    );
      Future.delayed(const Duration(seconds: 2),(){
        AppSettings.openAppSettings(type:AppSettingsType.notification);
      });

    }

  }

  //get token

Future<String> getDeviceToken() async{
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );
    String? token = await messaging.getToken();
    print("token==> $token");
    return token!;
}

}