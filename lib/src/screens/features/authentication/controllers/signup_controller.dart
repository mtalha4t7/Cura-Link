import 'package:get/get.dart';
import 'package:realm/realm.dart';

class SignUpController extends GetxController {
  final isSigningUp = false.obs;
  final app = App(AppConfiguration("cura_link-erilffo")); // Your App ID

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      isSigningUp.value = true;

      // Register user with MongoDB App Services
      await app.emailPasswordAuthProvider.registerUser(email, password);

      // Notify user to verify email
      Get.snackbar("Verification Sent",
          "Please check your email to confirm your account.",
          snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 5));
    } catch (e) {
      Get.snackbar("Error", "Sign-Up Failed: $e",
          snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 5));
    } finally {
      isSigningUp.value = false;
    }
  }
}
