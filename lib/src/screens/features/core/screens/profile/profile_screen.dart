import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cura_link/src/screens/features/core/screens/profile/update_profile_screen.dart';
import 'package:cura_link/src/screens/features/core/screens/profile/widgets/image_with_icon.dart';
import 'package:cura_link/src/screens/features/core/screens/profile/widgets/profile_menu.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../../common_widgets/buttons/primary_button.dart';
import '../../../../../constants/sizes.dart';
import '../../../../../constants/text_strings.dart';
import '../../../../../repository/authentication_repository/authentication_repository.dart';

import 'all_users.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String name = getUserFullName().toString();
    late String? email = getEmail();
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(LineAwesomeIcons.angle_left_solid)),
        title:
            Text(tProfile, style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          IconButton(
              onPressed: () {},
              icon: Icon(isDark ? LineAwesomeIcons.sun : LineAwesomeIcons.moon))
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(tDefaultSpace),
          child: Column(
            children: [
              const ImageWithIcon(),
              const SizedBox(height: 10),
              Text(name, style: Theme.of(context).textTheme.headlineMedium),
              Text(email.toString(),
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              TPrimaryButton(
                  isFullWidth: false,
                  width: 200,
                  text: tEditProfile,
                  onPressed: () => Get.to(() => UpdateProfileScreen())),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              ProfileMenuWidget(
                  title: "Settings",
                  icon: LineAwesomeIcons.cog_solid,
                  onPress: () {}),
              ProfileMenuWidget(
                  title: "Billing Details",
                  icon: LineAwesomeIcons.wallet_solid,
                  onPress: () {}),
              ProfileMenuWidget(
                  title: "User Management",
                  icon: LineAwesomeIcons.user_check_solid,
                  onPress: () => Get.to(() => AllUsers())),
              const Divider(),
              const SizedBox(height: 10),
              ProfileMenuWidget(
                  title: "Information",
                  icon: LineAwesomeIcons.info_solid,
                  onPress: () {}),
              ProfileMenuWidget(
                title: "Logout",
                icon: LineAwesomeIcons.sign_out_alt_solid,
                textColor: Colors.red,
                endIcon: false,
                onPress: () => _showLogoutModal(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _showLogoutModal() {
    Get.defaultDialog(
      title: "LOGOUT",
      titleStyle: const TextStyle(fontSize: 20),
      content: const Padding(
        padding: EdgeInsets.symmetric(vertical: 15.0),
        child: Text("Are you sure, you want to Logout?"),
      ),
      confirm: TPrimaryButton(
        isFullWidth: false,
        onPressed: () => AuthenticationRepository.instance.logout,
        text: "Yes",
      ),
      cancel: SizedBox(
          width: 100,
          child: OutlinedButton(
              onPressed: () => Get.back(), child: const Text("No"))),
    );
  }

  Future<String> getUserFullName() async {
    // Get the currently logged-in user
    final user = FirebaseAuth.instance.currentUser;

    // Check if the user is authenticated
    if (user != null) {
      try {
        // Reference to Firestore document in the `users` collection with the user's UID
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // Check if the document exists and has the `fullName` field
        if (userDoc.exists && userDoc.data()!.containsKey('fullName')) {
          return userDoc['FullName'];
        } else {
          return "No full name available";
        }
      } catch (e) {
        // Handle errors (e.g., document not found or network issues)
        return "Error retrieving full name";
      }
    } else {
      return "User not logged in";
    }
  }

  String? getEmail() {
    // Get the currently logged-in user
    final user = FirebaseAuth.instance.currentUser;

    // Check if the user exists and return their email
    if (user != null && user.email != null) {
      return user.email;
    } else {
      return "No email available";
    }
  }
}
