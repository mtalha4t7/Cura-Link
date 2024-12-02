import 'dart:convert';
import 'package:cura_link/src/screens/features/authentication/models/user_model_mongodb.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../constants/text_strings.dart';
import '../../../../repository/authentication_repository/authentication_repository.dart';
import '../../../../repository/user_repository/user_repository.dart';
import '../../../../shared prefrences/shared_prefrence.dart';
import '../../../../utils/helper/helper_controller.dart';
import '../models/user_model.dart';
import 'package:http/http.dart' as http;

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  /// TextField Controllers to get data from TextFields
  final showPassword = false.obs;
  final userEmail = TextEditingController();
  final userPassword = TextEditingController();

  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  /// Loader
  final isLoading = false.obs;
  final isGoogleLoading = false.obs;
  final isFacebookLoading = false.obs;

  /// [EmailAndPasswordLogin]
  Future<void> login() async {
    try {
      isLoading.value = true;
      if (!loginFormKey.currentState!.validate()) {
        isLoading.value = false;
        return;
      }

      final auth = AuthenticationRepository.instance;

      // Authenticate the user
      await auth.loginWithEmailAndPassword(
          userEmail.text.trim(), userPassword.text.trim());

      // Fetch user details from Firestore using the current user's email
      UserRepository userRepository = UserRepository.instance;
      UserModel user =
          await userRepository.getUserDetails(userEmail.text.trim());
      await saveUserType(user.userType!);

      // Check if the userType is set
      if (user.userType == null) {
        throw "User type is not set for this user.";
      }

      // Set initial screen after successful login and user type retrieval
      auth.setInitialScreen(auth.firebaseUser);
    } catch (e) {
      isLoading.value = false;
      Helper.errorSnackBar(title: tNoRecordFound, message: e.toString());
    }
  }

  Future<void> loginUser() async {
    try {
      isLoading.value = true;

      // Validate inputs
      if (userEmail.text.trim().isEmpty || userPassword.text.trim().isEmpty) {
        Get.snackbar(
          "Error",
          "Email and password are required",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        isLoading.value = false;
        return;
      }

      // Send login request to the backend
      final response =
          await _loginRequest(userEmail.text.trim(), userPassword.text.trim());

      // If the response is successful, handle the login
      if (response != null && response['status'] == 'success') {
        final userData = response['user'];
        final jwtToken = response['token'];

        if (userData != null && jwtToken != null) {
          // Save JWT token locally
          await saveJwtToken(jwtToken);

          // Convert response data to a UserModelMongoDB object
          UserModelMongoDB currentUser = UserModelMongoDB.fromDataMap(userData);

          // Call setInitialScreen with MongoDB user details
          AuthenticationRepository.instance
              .setInitialScreen(currentUser as User?);

          Get.snackbar(
            "Success",
            "Login successful!",
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
        } else {
          throw "Invalid response from server.";
        }
      } else {
        Get.snackbar(
          "Error",
          "Login failed. Please check your credentials.",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (error) {
      Get.snackbar(
        "Error",
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Helper function to make the login request
  Future<Map<String, dynamic>?> _loginRequest(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$ipAddress/api/auth/login"),
        headers: <String, String>{
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (error) {
      throw "Error logging in. Please try again.";
    }
  }
}
