import 'dart:convert';
import 'package:cura_link/src/constants/text_strings.dart';
import 'package:cura_link/src/screens/features/authentication/models/user_model_mongodb.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../../repository/authentication_repository/authentication_repository.dart';
import '../../../../repository/user_repository/user_repository.dart';
import '../../../../shared prefrences/shared_prefrence.dart';
import '../models/user_model.dart';

class SignUpController extends GetxController {
  static SignUpController get instance => Get.find();

  final showPassword = false.obs;
  final isGoogleLoading = false.obs;
  final isFacebookLoading = false.obs;
  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  // TextField Controllers to get data from TextFields
  final userEmail = TextEditingController();
  final userPassword = TextEditingController();
  final userName = TextEditingController();
  final userPhone = TextEditingController();

  /// Loader
  final isLoading = false.obs;

  Future<void> createUser() async {
    try {
      isLoading.value = true;
      if (!signupFormKey.currentState!.validate()) {
        isLoading.value = false;
        return;
      }

      // Load user type from shared preferences
      String? userType = await loadUserType();
      if (userType == null) {
        throw "User type is not set.";
      }

      // Create user model
      final user = UserModel(
        email: userEmail.text.trim(),
        password: userPassword.text.trim(),
        fullName: userName.text.trim(),
        phoneNo: userPhone.text.trim(),
        userType: userType,
      );

      // Authenticate user and create in repository
      // final auth = AuthenticationRepository.instance;
      // await auth.registerWithEmailAndPassword(user.email, user.password!);
      // await UserRepository.instance.mongoCreateUser(user);
      // await UserRepository.instance.createUser(user);
      // auth.setInitialScreen(auth.firebaseUser);
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5));
    }
  }

  Future<void> createAccount() async {
    try {
      // Validate user inputs
      if (userName.text.trim().isEmpty ||
          userEmail.text.trim().isEmpty ||
          userPassword.text.trim().isEmpty) {
        Get.snackbar(
          "Error",
          "All fields are required",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      // Create UserModelMongoDB object
      UserModelMongoDB userModel = UserModelMongoDB(
        userId: "",
        userName: userName.text.trim(),
        userEmail: userEmail.text.trim(),
        userPassword: userPassword.text.trim(),
        userAddress: "",
        jwtToken: "",
      );

      // Make the HTTP POST request
      http.Response httpResponse = await http.post(
        Uri.parse("$ipAddress/api/auth/signup"),
        body: jsonEncode(userModel.toJson()),
        headers: <String, String>{
          "Content-Type": "application/json",
        },
      );

      // Handle the response
      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        Get.snackbar(
          "Success",
          "Account created successfully",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        final auth = AuthenticationRepository.instance;
        auth.setInitialScreen(userModel);
      } else {
        final responseData = jsonDecode(httpResponse.body);
        Get.snackbar(
          "Error",
          responseData["message"] ?? "Something went wrong",
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
    }
  }
}
