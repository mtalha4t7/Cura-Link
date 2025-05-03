import 'package:cura_link/src/network_manager.dart';
import 'package:cura_link/src/notification_handler/notification_server.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:cura_link/src/mongodb/mongodb.dart';
import 'package:cura_link/src/repository/authentication_repository/authentication_repository.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
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
