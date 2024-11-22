import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
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
import '../../screens/features/core/screens/dashboards/medicalStoreDashboard/medicalstore_dashboard.dart';
import '../../screens/features/core/screens/dashboards/nurseDashboard/nurse_dashboard.dart';
import '../../shared prefrences/shared_prefrence.dart';
import 'exceptions/t_exceptions.dart';

/// -- README(Docs[6]) -- Bindings
class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  /// Variables
  late final Rx<User?> _firebaseUser;
  final _auth = FirebaseAuth.instance;
  final _phoneVerificationId = ''.obs;
  final userStorage =
      GetStorage(); // Use this to store data locally (e.g. OnBoarding)

  /// Getters
  User? get firebaseUser => _firebaseUser.value;

  String get getUserID => firebaseUser?.uid ?? "";

  String get getUserEmail => firebaseUser?.email ?? "";

  String get getDisplayName => firebaseUser?.displayName ?? "";

  String get getPhoneNo => firebaseUser?.phoneNumber ?? "";

  /// Loads when app Launch from main.dart
  @override
  void onReady() {
    _firebaseUser = Rx<User?>(_auth.currentUser);
    _firebaseUser.bindStream(_auth.userChanges());
    FlutterNativeSplash.remove();
    setInitialScreen(_firebaseUser.value);
    // ever(_firebaseUser, _setInitialScreen);
  }

  /// Setting initial screen
  Future<void> setInitialScreen(User? user) async {
    try {
      if (user != null) {
        // Fetch a fresh instance of the user to ensure the latest emailVerified status
        await user.reload();
        user = _auth.currentUser;

        if (user!.emailVerified) {
          // Check Shared Preferences for the userType
          String? userType = await loadUserType();

          // If userType is not found in Shared Preferences, fetch it from Firestore
          if (userType == null) {
            // Fetch the userType from Firestore if not found in Shared Preferences
            DocumentSnapshot userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            if (userDoc.exists) {
              userType = userDoc.get('userType');
              // Save userType to Shared Preferences for future use
              await saveUserType(userType!);
            }
          }

          // If userType is still null, handle the error or set a default value
          if (userType == null) {
            // Handle error appropriately
            print("Error: userType is null");
            // Navigate to an error screen or log out the user
            Get.offAll(() => ());
            return;
          }

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
              Get.offAll(() => MedicalStoreDashboard());
              break;
            default:
              Get.offAll(() => WelcomeScreen());
              break;
          }
        } else {
          // If the email is not verified, navigate to the email verification screen
          Get.offAll(() => MailVerification());
        }
      } else {
        // Handle the case where the user is null (first-time user or not logged in)
        bool isFirstTime = userStorage.read('isFirstTime') ?? true;
        if (isFirstTime) {
          Get.offAll(() => OnBoardingScreen());
        } else {
          Get.offAll(() => WelcomeScreen());
        }
      }
    } catch (e) {
      // Handle any errors that occur during the process
      print("Error in setInitialScreen: $e");
      Get.offAll(() => ());
    }
  }

  // Example function to get user type
  Future<String> getUserType(User user) async {
    try {
      // Fetch the user document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Check if the document exists
      if (userDoc.exists) {
        // Get the userType from the document
        String userType = userDoc.get('userType');
        return userType;
      } else {
        // Handle the case where the user document does not exist
        throw Exception("User document does not exist");
      }
    } catch (e) {
      // Handle any errors that occur during the fetch
      print("Error in getUserType: $e");
      throw e;
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
      print("error is  ====1");
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      print("error is  ====");

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
      // Google sign-out
      try {
        await GoogleSignIn().signOut();
        print("Google sign-out successful");
      } catch (e) {
        print("Error during Google sign-out: $e");
        throw 'Google sign-out failed';
      }

      // Facebook sign-out
      try {
        await FacebookAuth.instance.logOut();
        print("Facebook sign-out successful");
      } on MissingPluginException catch (e) {
        print("Facebook sign-out plugin missing: $e");
        // Handle case where Facebook logout is unavailable
        print("Skipping Facebook sign-out due to missing plugin.");
      } catch (e) {
        print("Error during Facebook sign-out: $e");
        throw 'Facebook sign-out failed';
      }

      // Firebase sign-out
      try {
        await FirebaseAuth.instance.signOut();
        print("Firebase sign-out successful");
      } catch (e) {
        print("Error during Firebase sign-out: $e");
        throw 'Firebase sign-out failed';
      }

      // Navigate to WelcomeScreen after successful logout
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      print("General logout error: $e");
      throw 'Unable to logout. Try again. Error: $e';
    }
  }
}
