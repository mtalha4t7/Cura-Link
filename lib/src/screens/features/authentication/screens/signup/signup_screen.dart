import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../common_widgets/form/form_header_widget.dart';
import '../../../../../common_widgets/form/social_footer.dart';
import '../../../../../constants/image_strings.dart';
import '../../../../../constants/sizes.dart';
import '../../../../../constants/text_strings.dart';
import 'widgets/signup_form_widget.dart';
import '../login/login_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(tDefaultSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FormHeaderWidget(
                    image: tWelcomeScreenImage,
                    title: tSignUpTitle,
                    subTitle: tSignUpSubTitle,
                    imageHeight: 0.15),
                SignUpFormWidget(),
                SocialFooter(
                    text1: tAlreadyHaveAnAccount,
                    text2: tLogin,
                    onPressed: () => Get.off(() => LoginScreen())),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
