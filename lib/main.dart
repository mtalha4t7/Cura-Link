import 'package:cura_link/screens/MainScreen.dart';
import 'package:cura_link/screens/patient/patient_main.dart';
import 'package:cura_link/splashScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() {

  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner:false,
      title: 'Cura Link',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PatientMain(),
    );
  }
}


