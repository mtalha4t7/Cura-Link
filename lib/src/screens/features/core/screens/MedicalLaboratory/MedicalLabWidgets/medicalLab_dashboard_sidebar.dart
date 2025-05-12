import 'package:cura_link/src/constants/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../repository/authentication_repository/authentication_repository.dart';
import '../MedicalLabProfile/medicalLab_profile_screen.dart';

class MedicalLabDashboardSidebar extends StatelessWidget {
  const MedicalLabDashboardSidebar({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: isDark ? Colors.grey[850] : Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: const Image(image: AssetImage(tLogoImage)),
            accountName: const Text('Medical Lab'),
            accountEmail: const Text('support@cura_link.com'),
            decoration:
            BoxDecoration(color: isDark ? Colors.grey[900] : Colors.blue),
          ),
          ListTile(
            leading:
            Icon(Icons.dashboard, color: isDark ? Colors.white : Colors.black),
            title: Text('Dashboard',
                style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            onTap: () {
              Get.toNamed('/lab-dashboard');
            },
          ),

          ListTile(
            leading: Icon(Icons.account_circle,
                color: isDark ? Colors.white : Colors.black),
            title: Text('Profile',
                style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MedicalLabProfileScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.settings,
                color: isDark ? Colors.white : Colors.black),
            title: Text('Settings',
                style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            onTap: () {
              Get.toNamed('/lab-settings');
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout,
                color: isDark ? Colors.white : Colors.black),
            title: Text('Logout',
                style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            onTap: () {
              // Handle logout action
              Get.defaultDialog(
                title: 'Logout',
                middleText: 'Are you sure you want to log out?',
                onConfirm: () {
                  // Perform logout
                  AuthenticationRepository.instance.logout();
                },
                onCancel: () {},
              );
            },
          ),
        ],
      ),
    );
  }
}
