import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:cura_link/src/screens/features/core/screens/Nurse/NurseProfile/Nurse_Update_Profile_Screen.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/PatientProfile/patient_all_users.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/PatientProfile/patient_update_profile_screen.dart';
import 'package:cura_link/src/screens/features/core/screens/profile/widgets/profile_menu.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../../../common_widgets/buttons/primary_button.dart';
import '../../../../../../constants/sizes.dart';
import '../../../../../../constants/text_strings.dart';
import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../repository/authentication_repository/authentication_repository.dart';

class NurseProfileScreen extends StatefulWidget {
  const NurseProfileScreen({super.key});

  @override
  _NurseProfileScreenState createState() => _NurseProfileScreenState();
}

class _NurseProfileScreenState extends State<NurseProfileScreen> {
  String email = "";
  String? name;
  Uint8List? profileImageBytes; // Updated for storing image bytes
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        email = user.email ?? '';
      });

      final nameFromDB = await UserRepository().getNurseUserName(email);
      setState(() {
        name = nameFromDB ?? "No full name available";
      });

      await _loadProfileImage(email);
    }
  }

  Future<void> _loadProfileImage(String email) async {
    try {
      final userData = await UserRepository.instance.getNurseUserByEmail(email);
      if (userData != null && userData['profileImage'] != null) {
        final base64Image = userData['profileImage'] as String;
        final decodedBytes = base64Decode(base64Image);
        setState(() {
          profileImageBytes = decodedBytes;
        });
      } else {
        print("No profile image found for email: $email");
      }
    } catch (e) {
      print("Error loading profile image: $e");
    }
  }

  Future<void> _uploadProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final selectedImage = File(pickedFile.path);

        // Convert image to Base64
        final bytes = await selectedImage.readAsBytes();
        final base64Image = base64Encode(bytes);

        // Upload image to MongoDB
        final collection = MongoDatabase.userNurseCollection;
        await UserRepository.instance.uploadProfileImage(
            email: email, base64Image: base64Image, collection: collection);

        // Reload the profile image
        await _loadProfileImage(email);
      }
    } catch (e) {
      print("Error uploading profile image: $e");
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
        title: Text(
          tProfile,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
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
                imageBytes: profileImageBytes,
                onEditPressed: _uploadProfileImage,
              ),
              const SizedBox(height: 10),
              Text(
                name ?? "No full name available",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(email, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              TPrimaryButton(
                isFullWidth: false,
                width: 200,
                text: tEditProfile,
                onPressed: () => Get.to(() => NurseProfileFormScreen()),
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
                onPress: _showLogoutModal,
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
      confirm: TPrimaryButton(
        isFullWidth: false,
        onPressed: () => AuthenticationRepository.instance.logout(),
        text: "Yes",
      ),
      cancel: SizedBox(
        width: 100,
        child: OutlinedButton(
          onPressed: () => Get.back(),
          child: const Text("No"),
        ),
      ),
    );
  }
}

class ProfilePictureWidget extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onEditPressed;

  const ProfilePictureWidget({
    super.key,
    required this.imageBytes,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: imageBytes != null ? MemoryImage(imageBytes!) : null,
          child: imageBytes == null
              ? const Icon(Icons.person, size: 50) // Default icon
              : null,
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
