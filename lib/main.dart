import 'package:cura_link/src/constants/text_strings.dart';
import 'package:cura_link/src/network_manager.dart';
import 'package:cura_link/src/notification_handler/notification_server.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:cura_link/src/mongodb/mongodb.dart';
import 'package:cura_link/src/repository/authentication_repository/authentication_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  Stripe.publishableKey=  dotenv.env['STRIPE_PUBLISHABLE_KEY']!;;
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await GetStorage.init();
  await dotenv.load(fileName: ".env");

  // Initialize MongoDB
  await MongoDatabase.connect();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .then((_) => Get.put(AuthenticationRepository()));
  Get.put(NetworkManager());
  // Initialize Notification Service

  runApp(const App());
  FlutterNativeSplash.remove();
}
