import 'package:cura_link/src/mongodb/mongodb.dart';
import 'package:cura_link/src/repository/authentication_repository/authentication_repository.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await MongoDatabase.connect();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .then((_) => Get.put(AuthenticationRepository()));
  FirebaseAppCheck appCheck = FirebaseAppCheck.instance;

  await appCheck.activate(androidProvider: AndroidProvider.playIntegrity);
  runApp(const App());
}
