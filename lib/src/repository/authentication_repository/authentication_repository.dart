import 'package:cura_link/src/repository/authentication_repository/exceptions/t_exceptions.dart';
import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:cura_link/src/screens/features/authentication/screens/mail_verification/mail_verification.dart';
import 'package:cura_link/src/screens/features/authentication/screens/on_boarding/on_boarding_screen.dart';
import 'package:cura_link/src/screens/features/authentication/screens/welcome/welcome_screen.dart';
import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabDashboard/medicalLab_dashboard.dart';
import 'package:cura_link/src/screens/features/core/screens/MedicalStore/MedicalStoreDashboard/MedicalStore_Dashboard.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientDashboard/patient_dashboard.dart';
import 'package:cura_link/src/shared%20prefrences/shared_prefrence.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../screens/features/authentication/screens/login/login_screen.dart';
import '../../screens/features/core/screens/Nurse/NurseDashboard/Nurse_Dashboard.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  late final Rx<User?> _firebaseUser;
  final _auth = FirebaseAuth.instance;
  final _phoneVerificationId = ''.obs;

  final GetStorage userStorage = GetStorage();

  User? get firebaseUser => _firebaseUser.value;

  String get getUserID => firebaseUser?.uid ?? "";

  String get getUserEmail => firebaseUser?.email ?? "";

  String get getDisplayName => firebaseUser?.displayName ?? "";

  String get getPhoneNo => firebaseUser?.phoneNumber ?? "";

  @override
  void onReady() {
    FlutterNativeSplash.remove();
    _firebaseUser = Rx<User?>(_auth.currentUser);
    _firebaseUser.bindStream(_auth.userChanges());
    FlutterNativeSplash.remove();
    setInitialScreen(firebaseUser);
  }

  /// Set the initial screen based on authentication state
  setInitialScreen(User? user) async {
    if (user != null) {
      // Check email verification status
      if (user.emailVerified) {
        // Load user type from Firebase or storage
        final firebaseUserType = await loadUserType();

        // Fetch user type from MongoDB
        final patient =
            await UserRepository.instance.getPatientByEmail(user.email!);
        final nurse =
            await UserRepository.instance.getNurseUserByEmail(user.email!);
        final lab =
            await UserRepository.instance.getLabUserByEmail(user.email!);
        final medicalStore = await UserRepository.instance
            .getMedicalStoreUserByEmail(user.email!);

        late final String? mongoUserType;

        if (patient != null) {
          mongoUserType =
              await UserRepository.instance.getPatientUserType(user.email!);
        } else if (nurse != null) {
          mongoUserType =
              await UserRepository.instance.getNurseUserType(user.email!);
        } else if (lab != null) {
          mongoUserType = await UserRepository.instance
              .getLabUserType(user.email!); // Corrected this line
        } else if (medicalStore != null) {
          mongoUserType = await UserRepository.instance
              .getMedicalStoreUserType(user.email!);
        }

        // Check if the user type matches
        if (firebaseUserType == mongoUserType) {
          // Navigate to the corresponding dashboard based on userType
          print(mongoUserType);

          switch (mongoUserType) {
            case 'Patient':
              Get.offAll(() => PatientDashboard());
              break;
            case 'Lab':
              Get.offAll(() => MedicalLabDashboard());
              break;
            case 'Nurse':
              Get.offAll(() => NurseDashboard());
              break;
            case 'Medical-Store':
              Get.offAll(() => MedicalStoreDashboard());
              break;
            default:
              Get.offAll(() => WelcomeScreen());
              break;
          }
        } else {
          // User type does not match, show options to the user
          Get.defaultDialog(
            title: "User Type Mismatch",
            content: Text(
                "This user is already logged in as $mongoUserType. Do you want to log in as another user? Press yes to log in again, or no to select a different user type."),
            confirm: ElevatedButton(
              onPressed: () async {
                await logout();
                Get.offAll(() => LoginScreen());
              },
              child: Text("Yes"),
            ),
            cancel: ElevatedButton(
              onPressed: () async {
                await logout();
                Get.offAll(() => WelcomeScreen());
              },
              child: Text("No"),
            ),
          );
        }
      } else {
        // Navigate to the email verification screen if not verified
        Get.offAll(() => MailVerification());
      }
    } else {
      // Handle first-time user onboarding
      final isFirstTime = userStorage.read('isFirstTime') ?? true;
      if (isFirstTime) {
        userStorage.write(
            'isFirstTime', false); // Set first time as false after initial use
        Get.offAll(() => OnBoardingScreen());
      } else {
        Get.offAll(() => WelcomeScreen());
      }
    }
  }

  /* ---------------------------- Email & Password sign-in ---------------------------------*/

  /// [EmailAuthentication] - LOGIN
  Future<void> loginWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      final result =
          TExceptions.fromCode(e.code); // Throw custom [message] variable
      throw result.message;
    } catch (_) {
      const result = TExceptions();
      throw result.message;
    }
  }

  /// [EmailAuthentication] - REGISTER
  Future<void> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      final ex = TExceptions.fromCode(e.code);
      throw ex.message;
    } catch (_) {
      const ex = TExceptions();
      throw ex.message;
    }
  }

  /// [EmailVerification] - MAIL VERIFICATION
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      final ex = TExceptions.fromCode(e.code);
      throw ex.message;
    } catch (_) {
      const ex = TExceptions();
      throw ex.message;
    }
  }

  /* ---------------------------- Federated identity & social sign-in ---------------------------------*/

  /// [GoogleAuthentication] - GOOGLE
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      final ex = TExceptions.fromCode(e.code);
      throw ex.message;
    } catch (_) {
      const ex = TExceptions();
      throw ex.message;
    }
  }

  ///[FacebookAuthentication] - FACEBOOK
  Future<UserCredential> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult loginResult =
          await FacebookAuth.instance.login(permissions: ['email']);

      // Create a credential from the access token
      final AccessToken accessToken = loginResult.accessToken!;
      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(accessToken.tokenString);

      // Once signed in, return the UserCredential
      return FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
    } on FirebaseAuthException catch (e) {
      throw e.message!;
    } on FormatException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Something went wrong. Try again!';
    }
  }

  /// [PhoneAuthentication] - LOGIN
  loginWithPhoneNo(String phoneNumber) async {
    try {
      await _auth.signInWithPhoneNumber(phoneNumber);
    } on FirebaseAuthException catch (e) {
      final ex = TExceptions.fromCode(e.code);
      throw ex.message;
    } catch (e) {
      throw e.toString().isEmpty
          ? 'Unknown Error Occurred. Try again!'
          : e.toString();
    }
  }

  /// [PhoneAuthentication] - REGISTER
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
          final result = TExceptions.fromCode(e.code);
          throw result.message;
        },
      );
    } on FirebaseAuthException catch (e) {
      final result = TExceptions.fromCode(e.code);
      throw result.message;
    } catch (e) {
      throw e.toString().isEmpty
          ? 'Unknown Error Occurred. Try again!'
          : e.toString();
    }
  }

  /// [PhoneAuthentication] - VERIFY PHONE NO BY OTP
  Future<bool> verifyOTP(String otp) async {
    var credentials = await _auth.signInWithCredential(
      PhoneAuthProvider.credential(
          verificationId: _phoneVerificationId.value, smsCode: otp),
    );
    return credentials.user != null ? true : false;
  }

  /* ---------------------------- ./end Federated identity & social sign-in ---------------------------------*/

  /// [LogoutUser] - Valid for any authentication.
  Future<void> logout() async {
    try {
      // Sign out from Google if signed in
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        print("Google user logged out successfully.");
      } else {
        print("No Google user is currently signed in.");
      }

      // Log out from Facebook if signed in
      try {
        await FacebookAuth.instance.logOut();
        print("Facebook user logged out successfully.");
      } catch (e) {
        print("Error logging out from Facebook: $e");
      }

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      print("Firebase user logged out successfully.");

      // Navigate to Welcome Screen and clear all routes
      Get.offAll(() => const WelcomeScreen());

      print("User  logged out successfully");
    } catch (e) {
      // Handle general errors
      print("Error during logout: $e");
      Get.snackbar("Logout Failed", "Unable to logout. Please try again.",
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
