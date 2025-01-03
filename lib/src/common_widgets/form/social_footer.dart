import 'package:cura_link/src/common_widgets/form/form_divider_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/image_strings.dart';
import '../../constants/sizes.dart';
import '../../constants/text_strings.dart';
import '../buttons/clickable_richtext_widget.dart';
import '../buttons/social_button.dart';

class SocialFooter extends StatelessWidget {
  const SocialFooter({
    super.key,
    this.text1 = tDontHaveAnAccount,
    this.text2 = tSignup,
    required this.onPressed,
  });

  final String text1, text2;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 6, bottom: tDefaultSpace),
      child: Column(
        children: [
          TSocialButton(
            image: tPhoneLogo,
            background: tGoogleBgColor,
            foreground: tGoogleForegroundColor,
            text: '${tConnectWith.tr} ${tPhone.tr}',
            onPressed: () => Get.to(() => const ()),
          ),
          const TFormDividerWidget(),
          // Uncomment the below code to enable Facebook social button if required
          // Obx(
          //   () => TSocialButton(
          //     image: tFacebookLogo,
          //     foreground: tWhiteColor,
          //     background: tFacebookBgColor,
          //     text: '${tConnectWith.tr} ${tFacebook.tr}',
          //     isLoading: controller.isFacebookLoading.value ? true : false,
          //     onPressed: controller.isGoogleLoading.value || controller.isLoading.value
          //         ? () {}
          //         : controller.isFacebookLoading.value
          //         ? () {}
          //         : () => controller.isFacebookLoading(),
          //   ),
          // ),
          ClickableRichTextWidget(
            text1: text1.tr,
            text2: text2.tr,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
