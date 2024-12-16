import 'dart:async';
import 'package:get/get.dart';
import 'package:realm/realm.dart';

class EmailVerificationController extends GetxController {
  static EmailVerificationController get instance => Get.find();

  final app =
      App(AppConfiguration("cura_link-erilffo")); // Replace with your app ID
  final verificationInProgress = false.obs;

  Future<void> sendVerificationEmail(String email) async {
    try {
      final result =
          await app.currentUser?.functions('sendVerificationEmail', [email]);
      if (result['status'] == 'pending') {
        print('Verification email sent.');
      } else {
        print('Failed to send email: ${result['error']}');
      }
    } catch (e) {
      print('Error sending verification email: $e');
    }
  }

  Future<void> resetPassword(
      String username, String token, String tokenId, String newPassword,
      {bool sendEmail = false, String? securityQuestionAnswer}) async {
    try {
      final result = await app.currentUser?.functions('resetPassword', [
        {
          'username': username,
          'token': token,
          'tokenId ': tokenId,
          'password': newPassword,
          'currentPasswordValid': true // or false based on your logic
        },
        sendEmail,
        securityQuestionAnswer
      ]);
      if (result['status'] == 'success') {
        print('Password reset successfully.');
      } else {
        print('Failed to reset password: ${result['message']}');
      }
    } catch (e) {
      print('Error resetting password: $e');
    }
  }
}
