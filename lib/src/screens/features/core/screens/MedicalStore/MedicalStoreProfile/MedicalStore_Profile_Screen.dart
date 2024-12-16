import 'dart:io';

import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/PatientProfile/patient_all_users.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/PatientProfile/patient_update_profile_screen.dart';
import 'package:cura_link/src/screens/features/core/screens/profile/widgets/profile_menu.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../../../common_widgets/buttons/primary_button.dart';
import '../../../../../../constants/sizes.dart';
import '../../../../../../constants/text_strings.dart';
import '../../../../../../repository/authentication_repository/authentication_repository.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  _PatientProfileScreenState createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  String email = "";
  Future<String>? name;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    email = getEmail().toString();
    // name = UserRepository().getFullNameByEmail(email);
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');
      try {
        profileImageUrl = await ref.getDownloadURL();
        setState(() {});
      } catch (e) {
        // Handle error (e.g., image not found)
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    // Check and request gallery permission
    var status = await Permission.photos.request();

    if (status.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child('${user.uid}.jpg');

          await ref.putFile(file);
          profileImageUrl = await ref.getDownloadURL();

          setState(() {});
        }
      }
    } else if (status.isDenied) {
      // Handle if permission is denied
      Get.snackbar(
          "Permission Denied", "Gallery access is required to upload images.");
    } else if (status.isPermanentlyDenied) {
      // Guide user to settings if permission is permanently denied
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(LineAwesomeIcons.angle_left_solid),
        ),
        title:
            Text(tProfile, style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(isDark ? LineAwesomeIcons.sun : LineAwesomeIcons.moon),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(tDefaultSpace),
          child: Column(
            children: [
              ProfilePictureWidget(
                imageUrl: profileImageUrl,
                onEditPressed: _uploadProfileImage,
              ),
              const SizedBox(height: 10),
              FutureBuilder<String>(
                future: name,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return Text(
                      snapshot.data ?? "No full name available",
                      style: Theme.of(context).textTheme.headlineMedium,
                    );
                  }
                },
              ),
              Text(email, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              TPrimaryButton(
                isFullWidth: false,
                width: 200,
                text: tEditProfile,
                onPressed: () => Get.to(() => PatientUpdateProfileScreen()),
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              ProfileMenuWidget(
                title: "Settings",
                icon: LineAwesomeIcons.cog_solid,
                onPress: () {},
              ),
              ProfileMenuWidget(
                title: "Billing Details",
                icon: LineAwesomeIcons.wallet_solid,
                onPress: () {},
              ),
              ProfileMenuWidget(
                title: "User Management",
                icon: LineAwesomeIcons.user_check_solid,
                onPress: () => Get.to(() => PatientAllUsers()),
              ),
              const Divider(),
              const SizedBox(height: 10),
              ProfileMenuWidget(
                title: "Information",
                icon: LineAwesomeIcons.info_solid,
                onPress: () {},
              ),
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

  void _showLogoutModal() {
    Get.defaultDialog(
      title: "LOGOUT",
      titleStyle: const TextStyle(fontSize: 20),
      content: const Padding(
        padding: EdgeInsets.symmetric(vertical: 15.0),
        child: Text("Are you sure, you want to Logout?"),
      ),
      // confirm: TPrimaryButton(
      //   isFullWidth: false,
      //   onPressed: () => AuthenticationRepository.instance.logout(),
      //   text: "Yes",
      // ),
      cancel: SizedBox(
        width: 100,
        child: OutlinedButton(
          onPressed: () => Get.back(),
          child: const Text("No"),
        ),
      ),
    );
  }

  String? getEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email ?? "No email available";
  }
}

class ProfilePictureWidget extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onEditPressed;

  const ProfilePictureWidget({
    Key? key,
    required this.imageUrl,
    required this.onEditPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null ? Icon(Icons.person, size: 50) : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(LineAwesomeIcons.camera_solid, color: Colors.blue),
            onPressed: onEditPressed,
          ),
        ),
      ],
    );
  }
}
