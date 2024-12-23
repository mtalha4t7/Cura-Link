import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:cura_link/src/screens/features/authentication/controllers/mail_verification_controller.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../../common_widgets/form/form_header_widget.dart';
import '../../../../../../constants/colors.dart';
import '../../../../../../constants/image_strings.dart';
import '../../../../../../constants/sizes.dart';
import '../../../../../../constants/text_strings.dart';

class ForgetPasswordMailScreen extends StatefulWidget {
  const ForgetPasswordMailScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ForgetPasswordMailScreenState createState() =>
      _ForgetPasswordMailScreenState();
}

class _ForgetPasswordMailScreenState extends State<ForgetPasswordMailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Future<void> _resetPassword() async {
  //   if (_formKey.currentState?.validate() ?? false) {
  //     setState(() {
  //       _isLoading = true;
  //     });
  //     try {
  // Check if the email is associated with an existing user
  // final signInMethods = await UserRepository.instance
  //     // .recordExist(_emailController.text.trim());

  //       // // ignore: unrelated_type_equality_checks
  //       if (signInMethods != _emailController.text.trim()) {
  //         // Send password reset email
  //         await FirebaseAuth.instance
  //             .sendPasswordResetEmail(email: _emailController.text.trim());
  //         // ignore: use_build_context_synchronously
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //               content: Text('Password reset link sent to your email')),
  //         );
  //       } else {
  //         // Email is not associated with any user
  //         // ignore: use_build_context_synchronously
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('No account found with this email')),
  //         );
  //       }
  //     } on FirebaseAuthException catch (e) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text(e.message ?? 'Failed to send reset link')),
  //       );
  //     } finally {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final bool isDark = brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(tDefaultSpace),
            child: Column(
              children: [
                const SizedBox(height: tDefaultSpace * 4),
                FormHeaderWidget(
                  imageColor: isDark ? tPrimaryColor : tSecondaryColor,
                  image: tForgetPasswordImage,
                  title: tForgetPassword,
                  subTitle: tForgetPasswordSubTitle,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  heightBetween: 30.0,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: tFormHeight),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: tEmail,
                          hintText: tEmail,
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),
                      SizedBox(
                        width: double.infinity,
                        // child: ElevatedButton(
                        //   onPressed: _isLoading ? null : EmailVerificationController.instance.resetPassword,
                        //   child: _isLoading
                        //       ? CircularProgressIndicator(color: Colors.white)
                        //       : const Text(tNext),
                        // ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
