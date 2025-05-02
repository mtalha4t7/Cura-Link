import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:cura_link/src/repository/authentication_repository/authentication_repository.dart';
import 'package:cura_link/src/mongodb/mongodb.dart';
import '../repository/user_repository/user_repository.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();
  UserRepository get _userRepository => Get.find<UserRepository>();

  // Notification channel setup
  static const String _channelId = 'cura_link_channel';
  static const String _channelName = 'Cura Link Notifications';
  static const String _channelDesc = 'Notification channel for Cura Link';
  static const String _bookingConfirmationType = 'booking_confirmation';

  /// Initialize the notification service
  Future<void> initialize() async {
    await _setupFCM();
    await _setupLocalNotifications();
    _setupInteractedMessage();
  }

  /// Setup Firebase Cloud Messaging
  Future<void> _setupFCM() async {
    try {
      // Request permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permissions');
      }

      // Get and save the FCM token
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
        debugPrint('FCM Token: $token');
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
    } catch (e) {
      debugPrint('Error setting up FCM: $e');
    }
  }

  /// Handle foreground messages
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    try {
      await _showNotification(message);
      _processMessageData(message.data);
    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }

  /// Handle background messages
  void handleBackgroundMessage(RemoteMessage message) {
    try {
      _processMessageData(message.data);
    } catch (e) {
      debugPrint('Error handling background message: $e');
    }
  }

  /// Setup local notifications plugin
  Future<void> _setupLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings();

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            try {
              final data = jsonDecode(response.payload!);
              _navigateBasedOnData(data);
            } catch (e) {
              debugPrint('Error parsing notification payload: $e');
            }
          }
        },
      );

      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: true,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('Error setting up local notifications: $e');
    }
  }

  /// Show notification
  Future<void> _showNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;

      // Use data payload if notification payload is null
      final title = notification?.title ?? data['title'] ?? 'New Notification';
      final body = notification?.body ?? data['body'] ?? 'You have a new message';

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        message.hashCode,
        title,
        body,
        platformDetails,
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Handle background/terminated message interaction
  void _setupInteractedMessage() {
    // App opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _processMessageData(message.data);
    });

    // App opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _processMessageData(message.data);
      }
    });
  }

  /// Process message data for both foreground and background cases
  void _processMessageData(Map<String, dynamic> data) {
    try {
      _navigateBasedOnData(data);
      // Add any additional processing here
    } catch (e) {
      debugPrint('Error processing message data: $e');
    }
  }

  /// Save FCM token to MongoD

  Future<void> saveToken(String token) async {
    debugPrint('[FCM] Attempting to save token: $token');
    try {
      await _saveTokenToDatabase(token);
      debugPrint('[FCM] Token saved successfully');
    } catch (e) {
      debugPrint('[FCM] Error saving token: $e');
      // You might want to retry later if this fails
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.email;
      if (userId == null || userId.isEmpty) {
        debugPrint('[FCM] No user ID available for saving FCM token');
        return;
      }

      debugPrint('[FCM] Current user ID: $userId');

      // Find which collection the user belongs to
      final user = await MongoDatabase.findUserPatient(userId) ??
          await MongoDatabase.findUserLab(userId) ??
          await MongoDatabase.findUserNurse(userId) ??
          await MongoDatabase.findUserMedicalStore(userId);

      if (user == null) {
        debugPrint('[FCM] User not found in any collection');
        return;
      }

      final userType = user['userType']?.toString();
      debugPrint('[FCM] Found user type: $userType');

      DbCollection? collection;
      switch (userType) {
        case 'Patient':
          collection = MongoDatabase.userPatientCollection;
          break;
        case 'Lab':
          collection = MongoDatabase.userLabCollection;
          break;
        case 'Nurse':
          collection = MongoDatabase.userNurseCollection;
          break;
        case 'MedicalStore':
          collection = MongoDatabase.userMedicalStoreCollection;
          break;
        default:
          debugPrint('[FCM] Unknown user type: $userType');
          return;
      }

      if (collection != null) {
        debugPrint('[FCM] Updating collection: $collection');

        final updateResult = await collection.updateOne(
          where.eq('userEmail', userId),
          modify
            ..set('fcmToken', token)
            ..set('updatedAt', DateTime.now()),
        );

        debugPrint('[FCM] Update result: $updateResult');

        if (updateResult.isSuccess) {
          debugPrint('[FCM] Token successfully saved to database');
        } else {
          debugPrint('[FCM] Failed to save token. Update not acknowledged');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[FCM] Error in _saveTokenToDatabase: $e');
      debugPrint('[FCM] Stack trace: $stackTrace');
      rethrow;
    }
  }


  /// Navigate based on notification data
  void _navigateBasedOnData(Map<String, dynamic> data) {
    try {
      final type = data['type']?.toString();
      if (type == _bookingConfirmationType) {
        final bookingId = data['bookingId']?.toString();
        if (bookingId != null && bookingId.isNotEmpty) {
          Get.toNamed('/booking-details', arguments: {'bookingId': bookingId});
        }
      }
      // Add more navigation cases as needed
    } catch (e) {
      debugPrint('Error navigating based on notification data: $e');
    }
  }

  /// Send a booking confirmation notification
  Future<void> sendBookingConfirmation({
    required String recipientUserId,
    required String labName,
    required String bookingId,
    required DateTime bookingTime,
  }) async {
    try {
      // Get recipient's FCM tokens from MongoDB
      final user = await MongoDatabase.findUserPatient(recipientUserId) ??
          await MongoDatabase.findUserLab(recipientUserId) ??
          await MongoDatabase.findUserNurse(recipientUserId) ??
          await MongoDatabase.findUserMedicalStore(recipientUserId);

      if (user == null) {
        debugPrint('Recipient user not found: $recipientUserId');
        return;
      }

      final tokens = List<String>.from(user['fcmTokens'] ?? []);
      if (tokens.isEmpty) {
        debugPrint('No FCM tokens found for user: $recipientUserId');
        return;
      }

      // Prepare notification data
      final messageData = {
        'title': 'Booking Confirmed',
        'body': 'Your booking at $labName has been confirmed',
        'type': _bookingConfirmationType,
        'bookingId': bookingId,
        'labName': labName,
        'bookingTime': bookingTime.toIso8601String(),
      };

      // Send to each device token
      for (final token in tokens) {
        try {
          await FirebaseMessaging.instance.sendMessage(
            to: token,
            data: messageData,
          );
          debugPrint('Notification sent to token: $token');
        } catch (e) {
          debugPrint('Error sending to token $token: $e');
        }
      }
    } catch (e) {
      debugPrint('Error sending booking confirmation: $e');
    }
  }
}