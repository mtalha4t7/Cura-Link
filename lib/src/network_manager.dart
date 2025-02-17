import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cura_link/firebase_options.dart';
import 'package:cura_link/src/mongodb/mongodb.dart';
import 'package:cura_link/src/repository/authentication_repository/authentication_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart'; // for SystemNavigator.pop()

class NetworkManager extends GetxController {
  var isConnected = false.obs;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final box = GetStorage(); // 🔹 Store last route

  @override
  void onInit() {
    super.onInit();
    _checkConnection();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results);
    });
  }

  Future<void> _checkConnection() async {
    var results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) async {
    bool hasConnection = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);

    if (hasConnection) {
      isConnected.value = true;
      await _initializeApp();
      // Remove any existing popup if there's a connection
      Get.back();
    } else {
      isConnected.value = false;
      // Only show the dialog if there's no active dialog already
      if (!Get.isDialogOpen!) {
        _showNoNetworkDialog();
      }
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Reconnect MongoDB and Firebase
      await MongoDatabase.connect();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Re-add AuthenticationRepository to ensure it is available
      Get.put(AuthenticationRepository(), permanent: true);
    } catch (e) {
      isConnected.value = false;
      // Show the dialog again if there's still no network
      if (!Get.isDialogOpen!) {
        _showNoNetworkDialog();
      }
    }
  }

  // Method to show "No Network" popup dialog
  void _showNoNetworkDialog() {
    Get.defaultDialog(
      title: "No Network",
      titleStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: Get.isDarkMode ? Colors.white : Colors.black,
      ),
      content: AnimatedOpacity(
        opacity: 1.0, // Full opacity to make content visible
        duration: const Duration(milliseconds: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.signal_wifi_off,
              size: 60,
              color: Get.isDarkMode ? Colors.white : Colors.black,
            ),
            const SizedBox(height: 10),
            Text(
              "You are not connected to the internet. Please try again or exit.",
              style: TextStyle(
                fontSize: 16,
                color: Get.isDarkMode ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      backgroundColor: Get.isDarkMode ? Colors.black87 : Colors.white,
      barrierDismissible: false, // Disable dismissing by tapping outside
      actions: [
        ElevatedButton(
          onPressed: () async {
            // Try to reconnect
            await retryConnection();
            if (isConnected.value) {
              Get.back(); // Close the dialog if connected
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Get.isDarkMode ? Colors.blueAccent : Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text("Try Again", style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            // Exit the app or close the dialog
            Get.back(); // Close the dialog
            SystemNavigator.pop(); // Close the app
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Get.isDarkMode ? Colors.redAccent : Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text("Exit", style: TextStyle(fontSize: 16)),
        ),
      ],
      titlePadding: const EdgeInsets.all(20),
      contentPadding: const EdgeInsets.all(20),
      radius: 15,
    );
  }

  Future<void> retryConnection() async {
    await _checkConnection();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
