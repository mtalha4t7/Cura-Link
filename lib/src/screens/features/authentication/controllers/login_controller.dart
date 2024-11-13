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

  Future<void> googleSignIn() async {
    try {
      isGoogleLoading.value = true;
      final auth = AuthenticationRepository.instance;

      // Sign In with Google
      await auth.signInWithGoogle();

      // Load user type from shared preferences
      String? userType = await loadUserType();

      // Check if user data already exists in Firestore
      if (!await UserRepository.instance.recordExist(auth.getUserEmail)) {
        // If the record does not exist, create a new user
        UserModel user = UserModel(
          email: auth.getUserEmail,
          password: '',
          fullName: auth.getDisplayName,
          phoneNo: auth.getPhoneNo,
          userType: userType ?? 'default', // or handle accordingly
        );
        await UserRepository.instance.createUser(user);
        // Save the new user type to SharedPreferences
      } else {
        // If the record exists, retrieve the user type from the database
        UserModel user =
            await UserRepository.instance.getUserDetails(auth.getUserEmail);
        userType = user.userType;

        // Store the user type in SharedPreferences
        await saveUserType(userType!);
      }

      isGoogleLoading.value = false;
      auth.setInitialScreen(auth.firebaseUser);
    } catch (e) {
      isGoogleLoading.value = false;
      Helper.errorSnackBar(title: tOhSnap, message: e.toString());
    }
  }

//   /// [FacebookSignInAuthentication]
//   Future<void> facebookSignIn() async {
//     try {
//       isFacebookLoading.value = true;
//       final auth = AuthenticationRepository.instance;
//
//       // Sign In with Facebook
//       await auth.signInWithFacebook();
//
//       // Load user type from shared preferences
//       String? userType = await loadUserType();
//       if (userType == null) {
//         throw "User type is not set.";
//       }
//
//       // Check if user data already exists in Firestore
//       if (!await UserRepository.instance.recordExist(auth.getUserID)) {
//         UserModel user = UserModel(
//           email: auth.getUserEmail,
//           password: '',
//           fullName: auth.getDisplayName,
//           phoneNo: auth.getPhoneNo,
//           userType: userType,
//         );
//         await UserRepository.instance.createUser(user);
//       }
//
//       isFacebookLoading.value = false;
//       auth.setInitialScreen(auth.firebaseUser);
//     } catch (e) {
//       isFacebookLoading.value = false;
//       Helper.errorSnackBar(title: tOhSnap, message: e.toString());
//     }
//   }
}
