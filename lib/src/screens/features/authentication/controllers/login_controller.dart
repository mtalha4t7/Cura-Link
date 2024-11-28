import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../constants/text_strings.dart';
import '../../../../repository/authentication_repository/authentication_repository.dart';
import '../../../../repository/user_repository/user_repository.dart';
import '../../../../shared prefrences/shared_prefrence.dart';
import '../../../../utils/helper/helper_controller.dart';
import '../models/user_model.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  /// TextField Controllers to get data from TextFields
  final showPassword = false.obs;
  final email = TextEditingController();
  final password = TextEditingController();

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
          email.text.trim(), password.text.trim());

      // Fetch user details from Firestore using the current user's email
      UserRepository userRepository = UserRepository.instance;
      UserModel user = await userRepository.getUserDetails(email.text.trim());
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
}
