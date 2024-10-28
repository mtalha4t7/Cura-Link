import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cura_link/src/screens/patient/patient_main.dart';
import 'package:cura_link/src/screens/patient/patient_sign_up.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/toast.dart';
import '../../firebaseImplemetations/firebase_authentication_services.dart';
import '../../services/user_service.dart';
import '../../widget/widget_support.dart';

class PatientLogin extends StatefulWidget {
  const PatientLogin({super.key});

  @override
  State<PatientLogin> createState() => _PatientLoginState();
}

class _PatientLoginState extends State<PatientLogin> {
  bool _isSigning = false;
  final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserService _userService = UserService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/registerbg.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.1),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Form(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Login",
                          style: AppWidget.headlineTextFieldStyle(),
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: _emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter email';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: AppWidget.semiBoldTextFieldStyle(),
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: _passwordController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            return null;
                          },
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: AppWidget.semiBoldTextFieldStyle(),
                            prefixIcon: const Icon(Icons.password_outlined),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Handle forgot password logic
                          },
                          child: Container(
                            padding: const EdgeInsets.only(top: 20),
                            alignment: Alignment.topRight,
                            child: const Text('Forgot Password?'),
                          ),
                        ),
                        const SizedBox(height: 30),
                        _isSigning
                            ? CircularProgressIndicator()
                            : Column(
                                children: [
                                  Container(
                                    alignment: Alignment.topLeft,
                                    child: ElevatedButton(
                                      onPressed: _signIn,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF00838F),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10.0),
                                        elevation: 8,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8.0, right: 8.0),
                                        child: const Text(
                                          'Login',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.0,
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: _signInWithGoogle,
                                    icon: FaIcon(
                                      FontAwesomeIcons.google,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      'Sign in with Google',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.0,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF00838F),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10.0, horizontal: 10),
                                      elevation: 8,
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account?",
                              style: TextStyle(fontSize: 11),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => PatientSignUp()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00838F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 10.0),
                                elevation: 8,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    right: 8.0, left: 8.0),
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.0,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _signIn() async {
    setState(() {
      _isSigning = true;
    });

    String email = _emailController.text;
    String password = _passwordController.text;

    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot? userDoc =
            await _userService.getUserDocument(user.uid);

        if (userDoc != null && userDoc.exists) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userEmail', userDoc['email'] ?? "");
          await prefs.setString('userName', userDoc['name'] ?? "");
          await prefs.setString('userProfilePic', userDoc['profilePic'] ?? "");

          showToast(message: "User is successfully signed in");
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PatientMain()),
          );
        } else {
          showToast(message: "User data not found, creating new document...");
          await _userService.saveUserData(user, user.displayName ?? "", '');
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userEmail', user.email ?? "");
          await prefs.setString('userName', user.displayName ?? "");
          await prefs.setString('userProfilePic', user.photoURL ?? "");

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PatientMain()),
          );
        }
      } else {
        showToast(message: "Failed to retrieve user");
      }
    } catch (e) {
      showToast(message: "Some error occurred: $e");
    } finally {
      setState(() {
        _isSigning = false;
      });
    }
  }

  void _signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken,
        );

        UserCredential userCredential =
            await _firebaseAuth.signInWithCredential(credential);
        User? user = userCredential.user;

        if (user != null) {
          DocumentSnapshot? userDoc =
              await _userService.getUserDocument(user.uid);

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

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userEmail', user.email ?? "");
          await prefs.setString('userName', user.displayName ?? "");
          await prefs.setString('userProfilePic', user.photoURL ?? "");

          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PatientMain()),
          );
        } else {
          showToast(message: "Failed to sign in with Google");
        }
      } else {
        showToast(message: "Google Sign In canceled");
      }
    } catch (e) {
      showToast(message: 'Some error occurred: $e');
    }
  }
}
