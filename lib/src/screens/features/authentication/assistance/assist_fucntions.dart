import 'package:flutter/material.dart';

displaySnackBar(BuildContext contextBuild, String messageText) {
  ScaffoldMessenger.of(contextBuild).showSnackBar(
    SnackBar(
      content: Text(
        messageText,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.blue,
      behavior: SnackBarBehavior.floating,
    ), // SnackBar
  );
}
