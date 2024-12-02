import 'package:cloud_firestore/cloud_firestore.dart';
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
    setInitialScreen(_firebaseUser.value);
  }

  /// Set the initial screen based on authentication state
  Future<void> setInitialScreen(User? user) async {
    try {
      if (user != null) {
        await user.reload();
        user = _auth.currentUser;
        if (user?.email == null) {
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
              Get.offAll(() => medicalstore_dashboard());
              break;
            default:
              Get.offAll(() => WelcomeScreen());
              break;
          }
        }
        if (user!.emailVerified) {
          String? userType = await loadUserType();

          if (userType == null) {
            DocumentSnapshot userDoc =
                await _firestore.collection('users').doc(user.uid).get();
            if (userDoc.exists) {
              userType = userDoc.get('userType');
              await saveUserType(userType!);
            }
          }

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
              Get.offAll(() => medicalstore_dashboard());
              break;
            default:
              Get.offAll(() => WelcomeScreen());
              break;
          }
        } else {
          Get.offAll(() => MailVerification());
        }
      } else {
        bool isFirstTime = userStorage.read('isFirstTime') ?? true;
        Get.offAll(isFirstTime ? OnBoardingScreen() : WelcomeScreen());
      }
    } catch (e) {
      Get.offAll(() => const LoginScreen());
    }
  }

  /* ----------------------------- Email Authentication ----------------------------- */

  Future<void> loginWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw TExceptions.fromCode((e as FirebaseAuthException).code).message;
    }
  }

  Future<void> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      throw TExceptions.fromCode((e as FirebaseAuthException).code).message;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
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
    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
    );
  }

  Future<void> signInWithCredential(PhoneAuthCredential credential) async {
    try {
      await _auth.signInWithCredential(credential);
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
      Get.offAllNamed('/welcome'); // Navigate to the login screen

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
    await _auth.signOut();
    Get.offAll(() => LoginScreen());
  }
}
