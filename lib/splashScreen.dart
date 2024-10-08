import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:cura_link/screens/MainScreen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  get splash => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
           body: AnimatedSplashScreen(
        splash: Center(
          child: Image.asset(
            "images/Splash.png",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ), // Image.asset
        ),
        nextScreen: const MainScreen(),
        backgroundColor: const Color.fromARGB(255, 107, 159, 248),
        splashIconSize: double.infinity, // This ensures the image takes the whole screen
      ),
    );
  }
}
