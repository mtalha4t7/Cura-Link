import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  Future<void> phoneAuthentication(String phoneNo) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNo,
        verificationCompleted: (credential) async {
          await _auth.signInWithCredential(credential);
        },
        codeSent: (verificationId, resendToken) {
          _phoneVerificationId.value = verificationId;
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _phoneVerificationId.value = verificationId;
        },
        verificationFailed: (e) {
          throw TExceptions.fromCode(e.code).message;
        },
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> verifyOtp({
    required String verificationId,
    required String userOtp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: userOtp,
      );

      // Sign in using the credential
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      throw Exception("Invalid OTP or Verification Failed");
    }
  }

  Future<void> resendOtp(String phoneNumber) async {
    await phoneAuthentication(phoneNumber);
  }

  /* ------------------------ Social Authentication ------------------------- */

  // Future<UserCredential?> signInWithGoogle() async {
  //   final googleUser = await GoogleSignIn().signIn();
  //   final googleAuth = await googleUser?.authentication;
  //   final credential = GoogleAuthProvider.credential(
  //     accessToken: googleAuth?.accessToken,
  //     idToken: googleAuth?.idToken,
  //   );
  //   return _auth.signInWithCredential(credential);
  // }

  // Future<UserCredential?> signInWithFacebook() async {
  //   final loginResult =
  //       await FacebookAuth.instance.login(permissions: ['email']);
  //   final credential =
  //       FacebookAuthProvider.credential(loginResult.accessToken!.token);
  //   return _auth.signInWithCredential(credential);
  // }

  /* ----------------------------- User Management --------------------------- */

  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
    await _auth.signOut();
    Get.offAll(() => LoginScreen());
  }
}
