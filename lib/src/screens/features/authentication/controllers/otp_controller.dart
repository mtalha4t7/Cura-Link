import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:cura_link/src/screens/features/authentication/screens/welcome/welcome_screen.dart';
import 'package:cura_link/src/screens/features/core/screens/dashboards/labDashboard/lab_dashboard.dart';
import 'package:cura_link/src/screens/features/core/screens/dashboards/nurseDashboard/nurse_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../repository/authentication_repository/authentication_repository.dart';
import '../../core/screens/Patient/patientDashboard/patient_dashboard.dart';

class OTPController extends GetxController {
  static OTPController get instance => Get.find();

  final AuthenticationRepository _authRepo = AuthenticationRepository.instance;
  final isLoading = false.obs;

  /// Handles OTP verification
  void verifyOtp({
    required String verificationId,
    required String userOtp,
    required VoidCallback onSuccess,
  }) async {
    isLoading.value = true; // Notify UI that verification is in progress
    try {
      await _authRepo.verifyOtp(
        verificationId: verificationId,
        userOtp: userOtp,
      );
      onSuccess(); // Invoke the success callback if verification succeeds
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false; // Notify UI that verification has completed
    }
  }

  /// Resend OTP for a phone number
  void resendOtp(String phoneNumber) async {
    isLoading.value = true;
    try {
      await _authRepo.resendOtp(phoneNumber);
      Get.snackbar(
        "Success",
        "OTP resent successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle successful OTP verification
  Future<void> onVerificationSuccess(String phoneNumber) async {
    try {
      // Check if user exists by phone number
      final UserRepository userRepo = UserRepository.instance;
      final userDetails =
          await userRepo.getUserDetailsByPhoneNumber(phoneNumber);

      if (userDetails != null) {
        // Extract userType from userDetails
        final userType = userDetails.userType;

        // Navigate based on userType
        switch (userType) {
          case 'Patient':
            Get.offAll(() => PatientDashboard());
            break;
          case 'Lab':
            Get.offAll(() => LabDashboard());
            break;
          case 'Nurse':
            Get.offAll(() => NurseDashboard());
            break;
          case 'Medical-Store':
            // Get.offAll(() => MedicalStoreDashboard());
            break;
          default:
            Get.offAll(() => WelcomeScreen());
            break;
        }
      } else {
        // Navigate to registration flow for new users
        // Get.offAll(() => UserInformationScreen());
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
