import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../../../common_widgets/buttons/primary_button.dart';
import '../../../../../../constants/sizes.dart';
import '../../../../../../constants/text_strings.dart';
import '../../../../../../utils/helper/helper_controller.dart';
import '../../../controllers/signup_controller.dart';

class SignUpFormWidget extends StatelessWidget {
  const SignUpFormWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignUpController());

    return Container(
      padding:
          const EdgeInsets.only(top: tFormHeight - 15, bottom: tFormHeight),
      child: Form(
        key: controller.signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: controller.userName,
              validator: (value) {
                if (value!.isEmpty) return 'Name cannot be empty';
                if (RegExp(r'\d').hasMatch(value)) return 'Name cannot contain Numbers';
                return null;

              },
              decoration: const InputDecoration(
                  label: Text(tFullName),
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  prefixIcon: Icon(LineAwesomeIcons.user)),
            ),
            const SizedBox(height: tFormHeight - 20),
            TextFormField(
              controller: controller.userEmail,
              validator: Helper.validateEmail,
              decoration: const InputDecoration(
                  label: Text(tEmail),
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  hintText: "example@mail.com",
                  hintStyle: TextStyle(fontSize: 14,fontFamily: 'Poppins'),
                  prefixIcon: Icon(LineAwesomeIcons.envelope)),
            ),
            const SizedBox(height: tFormHeight - 20),
            TextFormField(
              controller: controller.userPhone,
              keyboardType: TextInputType.phone,

              maxLength: 11,
              validator: (value) {
                if (value!.isEmpty) return 'Phone number cannot be empty';
                return null;
              },
              decoration: const InputDecoration(
                  label: Text(tPhoneNo),
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  hintText: "e,g 03439888369",
                  hintStyle: TextStyle(fontSize: 14,fontFamily: 'Poppins'),
                  prefixIcon: Icon(LineAwesomeIcons.phone_solid)),
            ),
            const SizedBox(height: tFormHeight - 20),
            Obx(
              () => TextFormField(
                controller: controller.userPassword,
                validator: Helper.validatePassword,
                obscureText: controller.showPassword.value ? false : true,
                decoration: InputDecoration(
                  suffixStyle: TextStyle(fontFamily: 'Poppins'),
                  label: const Text(tPassword),
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  prefixIcon: const Icon(Icons.fingerprint),
                  suffixIcon: IconButton(
                    icon: controller.showPassword.value
                        ? const Icon(LineAwesomeIcons.eye)
                        : const Icon(LineAwesomeIcons.eye_slash),
                    onPressed: () => controller.showPassword.value =
                        !controller.showPassword.value,
                  ),
                ),
              ),
            ),
            const SizedBox(height: tFormHeight - 10),
            Obx(
              () => TPrimaryButton(
                isLoading: controller.isLoading.value ? true : false,
                text: tSignup.tr,
                onPressed: controller.isFacebookLoading.value ||
                        controller.isGoogleLoading.value
                    ? () {}
                    : controller.isLoading.value
                        ? () {}
                        : () => controller.createUser(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
