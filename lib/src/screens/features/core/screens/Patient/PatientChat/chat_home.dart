import 'package:flutter/material.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 1,
        title: const Text("Cura Chat",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.normal,
                fontSize: 19)), // TextStyle // Text
        backgroundColor: Colors.white,
      ), // AppBar
    ); // Scaffold
  }
}
