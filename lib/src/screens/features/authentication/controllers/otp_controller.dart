import 'dart:ui';
import 'package:cura_link/src/repository/authentication_repository/authentication_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';


import '../../../../repository/user_repository/user_repository.dart';
import '../../../../shared prefrences/shared_prefrence.dart';
import '../models/user_model.dart'; // Example for user model

class OTPController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final auth = AuthenticationRepository.instance;

  final isLoading = false.obs;

  // Verifies the OTP entered by the user
  Future<void> verifyOtp({
    required String verificationId,
    required String userOtp,
    required String phoneNumber,
    required VoidCallback onSuccess,
  }) async {
    isLoading.value = true;
    try {
      // Verify the OTP
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: userOtp,
      );
      await _auth.signInWithCredential(credential);

      // Once OTP is verified, check if the user exists
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Check if the user exists in the database
        UserRepository userRepository = UserRepository.instance;
        UserModel? user = await userRepository.getUserDetailsByPhoneNumber(
            currentUser.phoneNumber.toString());

        if (user == null) {
          // User doesn't exist, create a new user
          await createUser(currentUser.phoneNumber.toString());
        } else {
          // User exists, proceed to sign in
          await saveUserType(user.userType!);
          // auth.setInitialScreen(user);

        }

        // Successfully signed in, navigate to dashboard
        onSuccess();
      } else {
        isLoading.value = false;
        Get.snackbar("Error", "Unable to sign in. Please try again.");
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "OTP verification failed: $e");
    }
  }

  // Re-sends the OTP to the user
  Future<void> resendOtp(String phoneNumber) async {
    isLoading.value = true;
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          isLoading.value = false;
          Get.snackbar("Success", "Phone number verified automatically!");
        },
        verificationFailed: (FirebaseAuthException e) {
          isLoading.value = false;
          Get.snackbar("Error", e.message ?? "Failed to resend OTP.");
        },
        codeSent: (String verificationId, int? resendToken) {
          isLoading.value = false;
          Get.snackbar("Success", "New OTP sent to your phone.");
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", e.toString());
    }
  }

  // Create user if they don't exist in the database
  Future<void> createUser(String phoneNumber) async {
    try {
      isLoading.value = true;
      // Get the user type, you can customize this part as per your app's logic
      String? userType = await loadUserType();
      if (userType == null) {
        throw "User type is not set.";
      }

      // Create the user model
      final user = UserModel(
        phoneNo: phoneNumber,
        userType: userType,
        fullName: "",
        // Set the full name or get it from another source if needed
        email: "", // You can add email or other fields if necessary
      );

      // Save the user to the repository/database
      await UserRepository.instance.createUser(user);

      // Set user type and navigate
      await saveUserType(userType);
      isLoading.value = false;
      // Navigate to the dashboard screen

      // auth.setInitialScreen(auth.firebaseUser);
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Failed to create user: $e");
    }
  }


}