import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:location/location.dart';
import '../../../../../../common_widgets/buttons/primary_button.dart';
import '../../../../../../constants/sizes.dart';

class MedicalStoreProfileFormScreen extends StatefulWidget {
  const MedicalStoreProfileFormScreen({super.key});

  @override
  State<MedicalStoreProfileFormScreen> createState() => _MedicalStoreProfileFormScreenState();
}

class _MedicalStoreProfileFormScreenState extends State<MedicalStoreProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  final Location _locationService = Location();
  bool _isLoading = true;
  String? _email;

  @override
  void initState() {
    super.initState();
    _email = FirebaseAuth.instance.currentUser?.email;
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      if (_email == null) return;

      final userData = await UserRepository.instance.getMedicalStoreUserByEmail(_email!);
      if (userData != null) {
        setState(() {
          _nameController.text = userData['userName']?.toString() ?? '';
          _phoneController.text = userData['userPhone']?.toString() ?? '';

          // Handle location which might be a Map or String
          if (userData['userAddress'] is String) {
            _locationController.text = userData['userAddress'];
          } else if (userData['location'] is Map) {
            final coords = userData['location']['coordinates'] as List;
            _locationController.text = '${coords[1]}, ${coords[0]}'; // lat, lng
          } else {
            _locationController.text = '';
          }
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load profile data: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    geo.LocationPermission permission;

    try {
      setState(() => _isLoading = true);

      serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar("Error", "Please enable location services");
        return;
      }

      permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission != geo.LocationPermission.whileInUse &&
            permission != geo.LocationPermission.always) {
          Get.snackbar("Error", "Location permissions required");
          return;
        }
      }

      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.best,
      );

      setState(() {
        _locationController.text =
        '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });

    } catch (e) {
      Get.snackbar("Error", "Location fetch failed: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate() || _email == null) return;

    try {
      setState(() => _isLoading = true);

      // Parse and validate location coordinates
      final locationParts = _locationController.text.split(', ');
      if (locationParts.length != 2) {
        throw FormatException("Invalid location format");
      }

      final lat = double.tryParse(locationParts[0]);
      final lng = double.tryParse(locationParts[1]);
      if (lat == null || lng == null) {
        throw FormatException("Invalid coordinate values");
      }

      // Build GeoJSON structure
      final updates = {
        'userName': _nameController.text.trim(),
        'userPhone': _phoneController.text.trim(),
        'location': {
          'type': 'Point',
          'coordinates': [lng, lat], // MongoDB expects [longitude, latitude]
        },
      };

      // Update database
      await UserRepository.instance.updateMedicalStoreUserByEmail(_email!, updates);

      Get.back();
      Get.snackbar("Success", "Profile updated successfully");

    } on FormatException catch (e) {
      Get.snackbar("Invalid Location", e.message);
    } catch (e) {
      Get.snackbar("Update Failed", "Please try again");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        leading: IconButton(
          icon: const Icon(LineAwesomeIcons.angle_left_solid),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(tDefaultSpace),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildFormField(
                controller: _nameController,
                label: "Store Name",
                icon: LineAwesomeIcons.store_alt_solid,
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: tFormHeight - 20),
              _buildFormField(
                controller: _phoneController,
                label: "Phone Number",
                icon: LineAwesomeIcons.phone_solid,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value!.isEmpty) return "Required";
                  if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
                    return "Invalid phone number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: tFormHeight - 20),
              _buildLocationField(),
              const SizedBox(height: tFormHeight),
              TPrimaryButton(
                text: "Save Changes",
                onPressed: _updateProfile,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildLocationField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: "Location",
              prefixIcon: const Icon(LineAwesomeIcons.map_marked_solid),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            readOnly: true,
          ),
        ),
        IconButton(
          icon: const Icon(LineAwesomeIcons.map_marker_solid, color: Colors.blue),
          onPressed: _getCurrentLocation,
        ),
      ],
    );
  }
}