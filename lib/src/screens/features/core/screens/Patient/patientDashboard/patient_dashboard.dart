import 'package:cura_link/src/screens/features/core/screens/Patient/PatientProfile/patient_profile_screen.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/patient_appbar.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/patient_banners.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/patient_categories.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/patient_search.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/top_searches.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../constants/image_strings.dart';
import '../../../../../../constants/sizes.dart';
import '../../../../../../constants/text_strings.dart';




class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        appBar: PatientDashboardAppBar(isDark: isDark),

       drawer: PatientDashboardSidebar(), // Extracted Drawer

        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(tDashboardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading
                Text(tDashboardTitle, style: txtTheme.bodyMedium),
                Text(tDashboardHeading, style: txtTheme.displayMedium),
                const SizedBox(height: tDashboardPadding),

                // Search Box
                PatientDashboardSearchBox(txtTheme: txtTheme),
                const SizedBox(height: tDashboardPadding),

                // Categories
                PatientDashboardCategories(txtTheme: txtTheme),
                const SizedBox(height: tDashboardPadding),

                // Banners
                PatientDashboardBanners(txtTheme: txtTheme, isDark: isDark),
                const SizedBox(height: tDashboardPadding),

                // Top Courses
                Text(
                  tDashboardTopCourses,
                  style: txtTheme.headlineMedium?.apply(fontSizeFactor: 1.2),
                ),
                PatientDashboardTopCourses(txtTheme: txtTheme, isDark: isDark)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class PatientDashboardSidebar extends StatelessWidget {
  const PatientDashboardSidebar({super.key});

  @override
  Widget build(BuildContext context) {


    return Container(
      width: 250, // Set a fixed width for the sidebar
      color: Colors.grey.shade200, // Set a background color for the sidebar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Header
          const UserAccountsDrawerHeader(
            currentAccountPicture: Image(image: AssetImage(tLogoImage)),
            accountName: Text('Patient Login'),
            accountEmail: Text('support@codingwithT.com'),
          ),

          // Sidebar Items
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Get.toNamed('/home'); // Adjust the route to your Home screen path
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              passToSettingsPage(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Shop'),
            onTap: () {
              Get.toNamed('/shop'); // Adjust the route to your Shop screen path
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Wishlist'),
            onTap: () {
              Get.toNamed('/wishlist'); // Adjust the route to your Wishlist screen path
            },
          ),
        ],
      ),
    );
  }
  passToSettingsPage(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => PatientProfileScreen()));
  }
}