import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabControllers/lab_profile_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:location/location.dart';
import '../../../../../../constants/sizes.dart';
import '../../../../../../constants/text_strings.dart';

class MedicalStoreProfileFormScreen extends StatefulWidget {
  const MedicalStoreProfileFormScreen({super.key});

  @override
  _MedicalStoreProfileFormScreenState createState() =>
      _MedicalStoreProfileFormScreenState();
}

class _MedicalStoreProfileFormScreenState
    extends State<MedicalStoreProfileFormScreen> {
  final TextEditingController phoneNoController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final Location location = Location();
  final UserRepository controller = UserRepository.instance;

  String? email = FirebaseAuth.instance.currentUser?.email;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUserProfile();
  }

  Future<void> _initializeUserProfile() async {
    try {
      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User is not logged in. Please log in.')),
        );
        return;
      }
      await _getName();
      await _getPhone();
      await _getLocation();
    } catch (e) {
      print('Error initializing user profile: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getName() async {
    try {
      final userNameResponse = await controller.getMedicalStoreUserName(email!);
      if (userNameResponse != null) {
        setState(() {
          fullNameController.text = userNameResponse;
        });
      } else {
        print('Failed to fetch user name or invalid data type.');
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
  }

  Future<void> _getPhone() async {
    try {
      final userPhoneResponse = await controller.getMedicalStorePhone(email!);
      if (userPhoneResponse != null) {
        setState(() {
          phoneNoController.text = userPhoneResponse;
        });
      } else {
        print('Failed to fetch phone number.');
      }
    } catch (e) {
      print('Error fetching phone number: $e');
    }
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      final locationData = await location.getLocation();
      setState(() {
        locationController.text =
        '${locationData.latitude}, ${locationData.longitude}';
      });
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileController = Get.put(MedicalLabProfileController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (email == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('User is not logged in.')),
                    );
                    return;
                  }

                  Map<String, dynamic> fieldsToUpdate = {
                    'userName': fullNameController.text.trim(),
                    'userPhone': phoneNoController.text.trim(),
                    'userAddress': locationController.text.trim(),
                  };

                  try {
                    await profileController.updateUserFields(
                        email!, fieldsToUpdate);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Profile updated successfully!')),
                    );
                  } catch (e) {
                    print('Error updating profile: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Failed to update profile.')),
                    );
                  }
                },
                child: const Text(tEditProfile),
              ),
            ),
            const SizedBox(height: tFormHeight),

          ],
        ),
      ),
    );
  }
}
