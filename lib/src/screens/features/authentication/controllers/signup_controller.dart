import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  final email = TextEditingController();
  final password = TextEditingController();
  final fullName = TextEditingController();
  final phoneNo = TextEditingController();

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
        email: email.text.trim(),
        password: password.text.trim(),
        fullName: fullName.text.trim(),
        phoneNo: phoneNo.text.trim(),
        userType: userType,
      );

      // Authenticate user and create in repository
      final auth = AuthenticationRepository.instance;
      await auth.registerWithEmailAndPassword(user.email, user.password!);
      await UserRepository.instance.createUser(user);
      auth.setInitialScreen(auth.firebaseUser);

    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5));
    }
  }

  Future<void> phoneAuthentication(String phoneNo) async {
    try {
      await AuthenticationRepository.instance.phoneAuthentication(phoneNo);
    } catch (e) {
      throw e.toString();
    }
  }
}
