import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cura_link/src/screens/features/authentication/models/user_model.dart';
import 'package:cura_link/src/screens/features/authentication/models/user_model_mongodb.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/features/authentication/screens/login/login_screen.dart';
import '../../screens/features/authentication/screens/mail_verification/mail_verification.dart';
import '../../screens/features/authentication/screens/on_boarding/on_boarding_screen.dart';
import '../../screens/features/authentication/screens/welcome/welcome_screen.dart';
import '../../screens/features/core/screens/Patient/patientDashboard/patient_dashboard.dart';
import '../../screens/features/core/screens/dashboards/labDashboard/lab_dashboard.dart';
import '../../screens/features/core/screens/MedicalStore/MedicalStoreDashboard/medicalstore_dashboard.dart';
import '../../screens/features/core/screens/dashboards/nurseDashboard/nurse_dashboard.dart';
import '../../shared prefrences/shared_prefrence.dart';
import 'exceptions/t_exceptions.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  // FirebaseAuth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Local storage
  final GetStorage userStorage = GetStorage();

  // Observable for phone verification ID
  // ignore: unused_field
  final RxString _phoneVerificationId = ''.obs;

  // Variables
  late final Rx<User?> _firebaseUser;
  late final UserModelMongoDB _mongodbUser;

  /// Getters
  User? get firebaseUser => _firebaseUser.value;
  String get getUserID => firebaseUser?.uid ?? '';
  String get getUserEmail => firebaseUser?.email ?? '';
  String get getDisplayName => firebaseUser?.displayName ?? '';
  String get getPhoneNo => firebaseUser?.phoneNumber ?? '';

  @override
  void onReady() {
    _firebaseUser = Rx<User?>(_auth.currentUser);
    _firebaseUser.bindStream(_auth.userChanges());
    FlutterNativeSplash.remove();
    setInitialScreen(_mongodbUser);
  }

  /// Set the initial screen based on authentication state
  Future<void> setInitialScreen(UserModelMongoDB user) async {
    try {
      // Check if the user exists
      if (user != null) {
        // Check if the user's email is null (as per your condition)
        if (user.userEmail != null) {
          // Retrieve the userType from shared preferences or some storage
          String? userType = await loadUserType();

          // Navigate to the appropriate dashboard based on userType
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
              Get.offAll(() =>());
              break;
            default:
              Get.offAll(() => WelcomeScreen());
              break;
          }
        } else {
          // Navigate to onboarding or welcome screen for first-time users
          bool isFirstTime = userStorage.read('isFirstTime') ?? true;
          Get.offAll(isFirstTime ? OnBoardingScreen() : WelcomeScreen());
        }
      } else {
        // If user is null, go to Login Screen
        Get.offAll(() => const LoginScreen());
      }
    } catch (e) {
      // Handle any unexpected errors
      Get.offAll(() => const LoginScreen());
    }
  }

  /* ----------------------------- Email Authentication ----------------------------- */

  Future<void> loginWithEmailAndPassword(String email, String password) async {
    try {
      // await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw TExceptions.fromCode((e as FirebaseAuthException).code).message;
    }
  }

  Future<void> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      // await _auth.createUserWithEmailAndPassword(
      //     email: email, password: password);
    } catch (e) {
      throw TExceptions.fromCode((e as FirebaseAuthException).code).message;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      // await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw TExceptions.fromCode((e as FirebaseAuthException).code).message;
    }
  }

  /* ------------------------ Phone Authentication --------------------------- */

  void verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) {
    // _auth.verifyPhoneNumber(
    //   phoneNumber: phoneNumber,
    //   timeout: const Duration(seconds: 60),
    //   verificationCompleted: onVerificationCompleted,
    //   verificationFailed: onVerificationFailed,
    //   codeSent: onCodeSent,
    //   codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
    // );
  }

  Future<void> signInWithCredential(PhoneAuthCredential credential) async {
    try {
      // await _auth.signInWithCredential(credential);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

// Clear JWT token and redirect to login screen
  Future<void> signOut() async {
    try {
      // Get the SharedPreferences instance
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Remove the JWT token from SharedPreferences
      await prefs.remove('jwtToken');

      // Optionally, clear other session data if needed
      // await prefs.remove('userDetails');

      // Redirect to the login screen
      // Navigate to the login screen
      Get.offAll(() => WelcomeScreen());
      // Optionally, display a success message
      Get.snackbar(
        "Success",
        "You have been logged out.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (error) {
      // Handle any errors
      Get.snackbar(
        "Error",
        "Something went wrong. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
    Get.offAll(() => LoginScreen());
  }
}