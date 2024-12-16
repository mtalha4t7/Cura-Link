import 'package:cura_link/src/screens/features/authentication/models/user_model_mongodb.dart';
import 'package:cura_link/src/screens/features/authentication/screens/login/login_screen.dart';
import 'package:cura_link/src/screens/features/authentication/screens/on_boarding/on_boarding_screen.dart';
import 'package:cura_link/src/screens/features/authentication/screens/welcome/welcome_screen.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientDashboard/patient_dashboard.dart';
import 'package:cura_link/src/screens/features/core/screens/dashboards/labDashboard/lab_dashboard.dart';
import 'package:cura_link/src/screens/features/core/screens/dashboards/nurseDashboard/nurse_dashboard.dart';
import 'package:cura_link/src/shared%20prefrences/shared_prefrence.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:realm/realm.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  final GetStorage userStorage = GetStorage();
  final app = App(AppConfiguration("cura_link-erilffo"));

  @override
  void onReady() {
    FlutterNativeSplash.remove();
    UserModelMongoDB mongodbUser = UserModelMongoDB();
    setInitialScreen(mongodbUser);
  }

  /// Set the initial screen based on authentication state
  Future<void> setInitialScreen(UserModelMongoDB user) async {
    try {
      if (user != null) {
        if (user.userEmail != null) {
          String? userType = await loadUserType();

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
              Get.offAll(
                  () => WelcomeScreen()); // Add Medical-Store Screen Here
              break;
            default:
              Get.offAll(() => WelcomeScreen());
              break;
          }
        } else {
          bool isFirstTime = userStorage.read('isFirstTime') ?? true;
          Get.offAll(isFirstTime ? OnBoardingScreen() : WelcomeScreen());
        }
      } else {
        Get.offAll(() => const LoginScreen());
      }
    } catch (e) {
      Get.offAll(() => const LoginScreen());
    }
  }

  /// Sign Up Method
  Future<void> signUp(String email, String password) async {
    await app.emailPasswordAuthProvider.registerUser(email, password);
  }

  /// Sign In Method
  Future<User> signIn(String email, String password) async {
    return await app.logIn(Credentials.emailPassword(email, password));
  }

  /// Email Verification Status
  bool isEmailVerified(User user) =>
      user.linkCredentials == AuthProviderType.emailPassword;

  /// Logout Method
  Future<void> logOut() async {
    try {
      await app.currentUser?.logOut(); // Logs out the current user
      await userStorage.erase(); // Clear saved preferences if any
      Get.offAll(() => const LoginScreen()); // Redirect to Login Screen
    } catch (e) {
      Get.snackbar("Logout Error", "Failed to log out: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
