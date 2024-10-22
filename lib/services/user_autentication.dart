import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cura_link/services/user_service.dart';

class UserAuthentication {
  final UserService _userService = UserService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Save user data to shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', user.email ?? "");
        await prefs.setString('userName', user.displayName ?? "");
        await prefs.setString('userProfilePic', user.photoURL ?? "");

        // Add user data to the database after successful login
        DocumentSnapshot? userDoc = await _userService.getUserDocument(user.uid);

        if (userDoc == null || !userDoc.exists) {
          await _userService.saveUserData(user, user.displayName ?? "", '');
        } else {
          await _userService.updateUserData(
            user.uid,
            user.displayName ?? "",
            user.email ?? "",
            user.photoURL ?? "",
          );
        }

        return "User is successfully signed in";
      } else {
        return "Failed to retrieve user";
      }
    } catch (e) {
      return "Some error occurred: $e";
    }
  }

  Future<String> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken,
        );

        UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
        User? user = userCredential.user;

        if (user != null) {
          // Save user data to shared preferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userEmail', user.email ?? "");
          await prefs.setString('userName', user.displayName ?? "");
          await prefs.setString('userProfilePic', user.photoURL ?? "");

          // Add user data to the database after successful login
          DocumentSnapshot? userDoc = await _userService.getUserDocument(user.uid);

          if (userDoc == null || !userDoc.exists) {
            await _userService.saveUserData(user, user.displayName ?? "", '');
          } else {
            await _userService.updateUserData(
              user.uid,
              user.displayName ?? "",
              user.email ?? "",
              user.photoURL ?? "",
            );
          }

          return "User is successfully signed in";
        } else {
          return "Failed to sign in with Google";
        }
      } else {
        return "Google Sign In canceled";
      }
    } catch (e) {
      return 'Some error occurred: $e';
    }
  }
}
