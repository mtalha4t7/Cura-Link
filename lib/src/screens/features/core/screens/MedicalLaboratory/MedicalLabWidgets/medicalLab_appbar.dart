import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabProfile/medicalLab_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../constants/colors.dart';
import '../../../../../../constants/image_strings.dart';


class MedicalLabDashboardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const MedicalLabDashboardAppBar({
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
      title: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorFiltered(
              colorFilter: isDark
                  ? const ColorFilter.mode(
                      Colors.white, // Invert color for dark mode
                      BlendMode.srcIn,
                    )
                  : const ColorFilter.mode(
                      Colors.black, // invert color for light mode
                      BlendMode.srcIn,
                    ),
              child: Image.asset(
                tLogoImage, // Assuming this is the logo image path=
                height: 55, // Adjust the height as needed
              ),
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 20, top: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isDark ? tSecondaryColor : tCardBgColor,
          ),
          child: IconButton(
            onPressed: navigateToProfile,
            icon: const Image(image: AssetImage(tUserProfileImage)),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);

  void navigateToProfile() {
    Get.to(() => const MedicalLabProfileScreen());
  }
}
