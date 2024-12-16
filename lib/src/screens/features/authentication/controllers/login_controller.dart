import 'package:cura_link/src/screens/features/authentication/models/user_model_mongodb.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cura_link/src/repository/authentication_repository/authentication_repository.dart';
import 'package:cura_link/src/shared%20prefrences/shared_prefrence.dart';
import 'package:cura_link/src/utils/helper/helper_controller.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  final showPassword = false.obs;
  final userEmail = TextEditingController();
  final userPassword = TextEditingController();
  final isLoading = false.obs;

  final GlobalKey<FormState> signInFormKey = GlobalKey<FormState>();

  /// Handle User Login
  Future<void> login() async {
    if (!signInFormKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      final email = userEmail.text.trim();
      final password = userPassword.text.trim();

      // Sign in using AuthenticationRepository
      final user =
          await AuthenticationRepository.instance.signIn(email, password);

      // Save JWT Token and user session
      await saveJwtToken(user.accessToken);
      await saveUserType("user"); // Example userType save (modify as needed)

      Get.snackbar("Success", "Login successful!");

      // Navigate to the Dashboard
      AuthenticationRepository.instance
          .setInitialScreen(user as UserModelMongoDB);
    } catch (e) {
      Helper.errorSnackBar(title: "Login Failed", message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
