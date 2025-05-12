import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:cura_link/src/screens/features/core/screens/Nurse/NurseProfile/nurse_update_profile_screen.dart';
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
import '../../Nurse/NurseChat/chat_home.dart';
import '../NurseDashboard/Nurse_Dashboard.dart';
import 'Nurse_Profile_Widgets/Nurse_Profile_Menu.dart';

class NurseProfileScreen extends StatefulWidget {
  const NurseProfileScreen({super.key});

  @override
  State<NurseProfileScreen> createState() => _NurseProfileScreenState();
}

class _NurseProfileScreenState extends State<NurseProfileScreen> {
  String email = "";
  String? name;
  String? phone;
  String? specialization;
  Uint8List? profileImageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  int _currentIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return;

      setState(() {
        email = user.email!;
        _isLoading = true;
      });

      final userData = await UserRepository.instance.getNurseUserByEmail(email);
      if (userData != null) {
        setState(() {
          name = userData['userName'] ?? "No name provided";
          phone = userData['userPhone'] ?? "No phone provided";
          specialization = userData['specialization'] ?? "General Nurse";

          if (userData['profileImage'] != null) {
            profileImageBytes = base64Decode(userData['profileImage']);
          }
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load profile data");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final bytes = await File(pickedFile.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      await UserRepository.instance.uploadProfileImage(
        email: email,
        base64Image: base64Image,
        collection: MongoDatabase.userNurseCollection,
      );

      setState(() => profileImageBytes = bytes);
    } catch (e) {
      Get.snackbar("Error", "Failed to upload image");
    }
  }

  @override
  Widget build(BuildContext context) {
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(tProfile, style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(LineAwesomeIcons.sign_out_alt_solid),
            onPressed: _showLogoutModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(tDefaultSpace),
        child: Column(
          children: [
            ProfilePictureWidget(
              imageBytes: profileImageBytes,
              onEditPressed: _uploadProfileImage,
            ),
            const SizedBox(height: 20),
            Text(name!, style: Theme.of(context).textTheme.headlineMedium),
            Text(email, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text(specialization!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 30),
            TPrimaryButton(
              text: tEditProfile,
              onPressed: () => Get.to(() => const NurseProfileFormScreen()),
            ),
            const SizedBox(height: 30),
            _buildProfileInfoSection(),
            const SizedBox(height: 30),
            _buildSettingsSection(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              Get.offAll(() => NurseDashboard());
              break;
            case 1:
              // Get.offAll(() => BookingsScreen());
              break;
            case 2:
              Get.offAll(() => ChatHomeScreen());
              break;
            case 3:
            // Already on profile screen
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        selectedItemColor: isDark ? Colors.blueAccent : Colors.blue,
        unselectedItemColor: isDark ? Colors.white70 : Colors.black54,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }


  Widget _buildProfileInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ProfileInfoTile(
              icon: LineAwesomeIcons.phone_solid,
              title: "Contact Number",
              value: phone!,
            ),
            const Divider(),
            ProfileInfoTile(
              icon: LineAwesomeIcons.envelope_solid,
              title: "Email",
              value: email,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      children: [
        ProfileMenuWidget(
          title: "Availability",
          icon: LineAwesomeIcons.calendar_check_solid,
          onPress: () {},
        ),
        ProfileMenuWidget(
          title: "Notifications",
          icon: LineAwesomeIcons.bell_solid,
          onPress: () {},
        ),
        ProfileMenuWidget(
          title: "Change Password",
          icon: LineAwesomeIcons.lock_solid,
          onPress: () {},
        ),
      ],
    );
  }


  void _showLogoutModal() {
    Get.defaultDialog(
      title: "LOGOUT",
      content: const Text("Are you sure you want to logout?"),
      actions: [
        OutlinedButton(
          onPressed: () => Get.back(),
          child: const Text("No"),
        ),
        SizedBox(
          width: 90, // Match this size with your "No" button's typical width
          child: TPrimaryButton(
            onPressed: () => AuthenticationRepository.instance.logout(),
            text: "Yes",
          ),
        ),
      ],
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
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: ClipOval(
            child: imageBytes != null
                ? Image.memory(imageBytes!, fit: BoxFit.cover)
                : const Icon(Icons.person, size: 60),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              onPressed: onEditPressed,
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const ProfileInfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
    );
  }
}