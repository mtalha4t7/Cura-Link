import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../PatientControllers/lab_booking_controller.dart';
import '../patientWidgets/lab_users_card.dart';
import 'temp_userModel.dart';

class LabBookingScreen extends StatefulWidget {
  const LabBookingScreen({super.key});

  @override
  _LabBookingScreenState createState() => _LabBookingScreenState();
}

class _LabBookingScreenState extends State<LabBookingScreen> {
  final PatientLabBookingController _controller = PatientLabBookingController();
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;
  List<ShowLabUserModel> _labs = [];
  bool _isLoading = true;
  String _locationError = '';

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _loadLabs();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationError = 'Location services are disabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationError = 'Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _locationError = 'Location permissions are permanently denied');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      setState(() => _locationError = 'Could not get location: $e');
    }
  }

  Future<void> _loadLabs() async {
    try {
      final labs = await _controller.fetchAllUsers();
      setState(() => _labs = labs);
      _updateMarkers();
    } catch (e) {
      debugPrint("Error loading labs: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<LatLng> _geocodeAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
    // Fallback to random nearby location
    final rnd = 0.01 * (0.5 - Random().nextDouble());
    return LatLng(
      _currentLocation!.latitude + rnd,
      _currentLocation!.longitude + rnd,
    );
  }

  Future<void> _updateMarkers() async {
    _markers.clear();

    // Add current location marker
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Add lab markers
    for (var lab in _labs) {
      try {
        final labLocation = await _geocodeAddress(lab.userAddress);
        _markers.add(
          Marker(
            markerId: MarkerId(lab.id.toString()),
            position: labLocation,
            infoWindow: InfoWindow(
              title: lab.userName,
              snippet: lab.userAddress,
            ),
            onTap: () => _showLabDetails(lab),
          ),
        );
      } catch (e) {
        debugPrint("Error adding marker for ${lab.userName}: $e");
      }
    }
    setState(() {});
  }

  void _showLabDetails(ShowLabUserModel lab) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lab.userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(lab.userAddress),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  print("Selected Lab: ${lab.userName}");
                },
                child: const Text('Book Appointment'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_locationError.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Find Labs')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _locationError,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _determinePosition,
                  child: const Text('Retry Location'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Labs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentLocation != null) {
                _mapController.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentLocation!, 14),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(0, 0),
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                if (_currentLocation != null) {
                  _mapController.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentLocation!, 14),
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}