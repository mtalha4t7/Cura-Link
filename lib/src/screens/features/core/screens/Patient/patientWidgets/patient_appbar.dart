import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../constants/colors.dart';
import '../../../../../../constants/image_strings.dart';
import '../../../../../../constants/text_strings.dart';
import '../PatientProfile/patient_profile_screen.dart';

class PatientDashboardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const PatientDashboardAppBar({
    super.key,
    required this.isDark,
  });
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      title: Text(tAppName, style: Theme.of(context).textTheme.headlineMedium),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 20, top: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isDark ? tSecondaryColor : tCardBgColor,
          ),
          child: IconButton(
            onPressed: navigateToProfile,

            // onPressed: () => AuthenticationRepository.instance.logout(),
            icon: const Image(image: AssetImage(tUserProfileImage)),
          ),
        )
      ],
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => const Size.fromHeight(55);

  void navigateToProfile() {
    Get.to(() => const PatientProfileScreen());
  }
}
