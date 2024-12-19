import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:location/location.dart';  // Add this import for location services
import '../../../../../../constants/sizes.dart';
import '../../../../../../constants/text_strings.dart';
import '../../../controllers/profile_controller.dart';
import '../../../../authentication/models/user_model.dart';

class PatientProfileFormScreen extends StatefulWidget {
  const PatientProfileFormScreen({super.key});

  @override
  _PatientProfileFormScreenState createState() => _PatientProfileFormScreenState();
}

class _PatientProfileFormScreenState extends State<PatientProfileFormScreen> {
  final TextEditingController phoneNoController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final Location location = Location();
  late UserModel user;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _getLocation();
  }

  Future<void> _initializeUser() async {
    // Fetch the user data from the controller or any other shared state
    final controller = Get.put(UserRepository());
    final firebaseUser= FirebaseAuth.instance.currentUser;
    final Uemail=firebaseUser?.email;
    user = (await controller.getUserByEmail(Uemail!)) as UserModel; // Assuming getUser() fetches the current user

    setState(() {
      fullNameController.text = user.fullName ?? ''; // Pre-fill with user's full name
      phoneNoController.text = user.phoneNo ?? ''; // Pre-fill with user's phone number
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

    return Form(
      child: Column(
        children: [
          TextFormField(
            controller: fullNameController,
            decoration: const InputDecoration(
                label: Text(tFullName),
                prefixIcon: Icon(LineAwesomeIcons.user)),
          ),
          const SizedBox(height: tFormHeight - 20),
          TextFormField(
            controller: phoneNoController,
            decoration: const InputDecoration(
                label: Text(tPhoneNo),
                prefixIcon: Icon(LineAwesomeIcons.phone_solid)),
          ),
          const SizedBox(height: tFormHeight - 20),
          TextFormField(
            controller: locationController,
            decoration: const InputDecoration(
                label: Text('Location'),
                prefixIcon: Icon(LineAwesomeIcons.map_marked_solid)),
            readOnly: true,
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
                  'location': locationController.text.trim(),
                };

                await controller.updateUserFields(user.email, fieldsToUpdate);
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
                            fontWeight: FontWeight.bold, fontSize: 12))
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    elevation: 0,
                    foregroundColor: Colors.red,
                    side: BorderSide.none),
                child: const Text(tDelete),
              ),
            ],
          )
        ],
      ),
    );
  }
}
