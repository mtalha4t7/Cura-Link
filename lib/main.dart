import 'package:cura_link/screens/patient/patient_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Platform.isAndroid
      ? await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyC19ZR2Dkmc-FVVNICESMpIimGdt0HoTyw",
            appId: "1:346007822005:android:40b5f5183c8da0e42568fc",
            messagingSenderId: "346007822005",
            projectId: "cura-link",
            storageBucket: "cura-link.appspot.com",
          ),
        )
      : await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cura Link',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PatientLogin(),
    );
  }
}
