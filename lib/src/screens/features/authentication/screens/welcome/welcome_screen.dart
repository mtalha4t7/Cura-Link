import 'package:cura_link/src/screens/features/authentication/screens/welcome/welcome_widgets/advance_button.dart';
import 'package:cura_link/src/shared%20prefrences/shared_prefrence.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../constants/colors.dart';
import '../../../../../constants/image_strings.dart';
import '../../../../../constants/text_strings.dart';
import '../../../../../utils/animations/fade_in_animation/animation_design.dart';
import '../../../../../utils/animations/fade_in_animation/fade_in_animation_controller.dart';
import '../../../../../utils/animations/fade_in_animation/fade_in_animation_model.dart';
import '../signup/signup_screen.dart';

//Wellcomescreen extends Statelesswidget
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FadeInAnimationController());
    controller.animationIn();

    var mediaQuery = MediaQuery.of(context);
    var width = mediaQuery.size.width;
    var height = mediaQuery.size.height;
    var brightness = mediaQuery.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        backgroundColor: isDarkMode ? tDarkColor : tPrimaryColor,
        body: Stack(
          children: [
            TFadeInAnimation(
              isTwoWayAnimation: false,
              durationInMs: 1200,
              animate: TAnimatePosition(
                bottomAfter: 0,
                bottomBefore: -100,
                leftBefore: 0,
                leftAfter: 0,
                topAfter: 0,
                topBefore: 0,
                rightAfter: 0,
                rightBefore: 0,
              ),
              child: Container(
                padding: const EdgeInsets.only(left: 15, right: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Hero(
                      tag: 'welcome-image-tag',
                      child: Image(
                        image: const AssetImage(tLogoImage),
                        width: width * 0.5,
                        height: height * 0.2,
                      ),
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1.0),
                          child: Text(
                            tWelcomeTitle,
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: Text(
                            tWelcomeSubTitle,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: AdvanceButton(
                            imagePath: tPatientImage,
                            title: 'Patient',
                            onTap: () async {
                              await saveUserType("Patient");
                              Get.to(() => const SignupScreen());
                            },
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: AdvanceButton(
                            imagePath: tMedicalStoreImage,
                            title: 'Medic-Store',
                            onTap: () async {
                              await saveUserType("Medical-Store");
                              Get.to(() => const SignupScreen());
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: AdvanceButton(
                            imagePath: tNurseImage,
                            title: 'Nurse',
                            onTap: () async {
                              await saveUserType("Nurse");
                              Get.to(() => const SignupScreen());
                            },
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: AdvanceButton(
                            imagePath: tLabImage,
                            title: 'Lab',
                            onTap: () async {
                              await saveUserType("Lab");
                              Get.to(() => const SignupScreen());
                            },
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
