import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:location/location.dart';
import '../../../../../../constants/sizes.dart';
import '../../../../../../constants/text_strings.dart';
import '../../../controllers/profile_controller.dart';

class MedicalStoreProfileFormScreen extends StatefulWidget {
  const MedicalStoreProfileFormScreen({super.key});

  @override
  _MedicalStoreProfileFormScreenState createState() => _MedicalStoreProfileFormScreenState();
}

class _MedicalStoreProfileFormScreenState extends State<MedicalStoreProfileFormScreen> {
  final TextEditingController phoneNoController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userTypeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final Location location = Location();
  final controller = UserRepository.instance;
  final email = FirebaseAuth.instance.currentUser?.email;
  late String userName;
  late String userPhone;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUserProfile();
  }

  Future<void> _initializeUserProfile() async {
    await _getName();
    await _getPhone();
    await _getLocation();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getName() async {
    userName = (await controller.getFullNameByEmail(email!))!;
    setState(() {
      fullNameController.text = userName;
    });
  }

  Future<void> _getPhone() async {
    userPhone = (await controller.getPhoneNumberByEmail(email!))!;
    setState(() {
      phoneNoController.text = userPhone;
    });
  }

  Future<void> _getLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    // Check if the location service is enabled
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    // Check if the location permission is granted
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Get the current location
    _locationData = await location.getLocation();
    setState(() {
      locationController.text = '${_locationData.latitude}, ${_locationData.longitude}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
        child: Column(
          children: [
            TextFormField(
              controller: fullNameController,
              decoration: const InputDecoration(
                label: Text(tFullName),
                prefixIcon: Icon(LineAwesomeIcons.user),
              ),
            ),
            const SizedBox(height: tFormHeight - 20),
            TextFormField(
              controller: phoneNoController,
              decoration: const InputDecoration(
                label: Text(tPhoneNo),
                prefixIcon: Icon(LineAwesomeIcons.phone_solid),
              ),
            ),
            const SizedBox(height: tFormHeight - 20),
            GestureDetector(
              onTap: _getLocation,
              child: AbsorbPointer(
                child: TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    label: Text('Location'),
                    prefixIcon: Icon(LineAwesomeIcons.map_marked_solid),
                  ),
                  readOnly: true,
                ),
              ),
            ),
            const SizedBox(height: tFormHeight),

            /// -- Form Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Map<String, dynamic> fieldsToUpdate = {
                    'userName': fullNameController.text.trim(),
                    'userPhone': phoneNoController.text.trim(),
                    'userAddress': locationController.text.trim(),
                  };

                  await controller.updateUserFields(email!, fieldsToUpdate);

                  // Show snack bar message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile updated successfully!'),
                    ),
                  );
                },
                child: const Text(tEditProfile),
              ),
            ),
            const SizedBox(height: tFormHeight),

            /// -- Created Date and Delete Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text.rich(
                  TextSpan(
                    text: tJoined,
                    style: TextStyle(fontSize: 12),
                    children: [
                      TextSpan(
                        text: tJoinedAt,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    elevation: 0,
                    foregroundColor: Colors.red,
                    side: BorderSide.none,
                  ),
                  child: const Text(tDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
