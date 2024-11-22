import 'package:cura_link/src/constants/image_strings.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/PatientProfile/patient_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PatientDashboardSidebar extends StatelessWidget {
  const PatientDashboardSidebar({super.key, required this.isDark});
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
            accountName: const Text('Patient Login'),
            accountEmail: const Text('support@cura_link.com'),
            decoration:
                BoxDecoration(color: isDark ? Colors.grey[900] : Colors.blue),
          ),
          ListTile(
            leading:
                Icon(Icons.home, color: isDark ? Colors.white : Colors.black),
            title: Text('Home',
                style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            onTap: () {
              Get.toNamed('/home');
            },
          ),
          ListTile(
            leading:
                Icon(Icons.person, color: isDark ? Colors.white : Colors.black),
            title: Text('Profile',
                style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PatientProfileScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_bag,
                color: isDark ? Colors.white : Colors.black),
            title: Text('Shop',
                style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            onTap: () {
              Get.toNamed('/shop');
            },
          ),
          ListTile(
            leading: Icon(Icons.favorite,
                color: isDark ? Colors.white : Colors.black),
            title: Text('Wishlist',
                style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            onTap: () {
              Get.toNamed('/wishlist');
            },
          ),
        ],
      ),
    );
  }
}
