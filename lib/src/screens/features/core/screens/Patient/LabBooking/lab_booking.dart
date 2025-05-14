import 'dart:math';
import 'dart:ui' as ui;
import 'package:cura_link/src/screens/features/core/screens/Patient/LabBooking/show_lab_services.dart';
import 'package:cura_link/src/shared%20prefrences/shared_prefrence.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:matcher/expect.dart';
import '../PatientControllers/lab_booking_controller.dart';
import '../patientWidgets/lab_users_card.dart';
import 'temp_userModel.dart';

class LabBookingScreen extends StatefulWidget {
  const LabBookingScreen({super.key});

  @override
  _LabBookingScreenState createState() => _LabBookingScreenState();
}

class _LabBookingScreenState extends State<LabBookingScreen> {
  final LabBookingController _controller = LabBookingController();
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;
  List<ShowLabUserModel> _labs = [];
  bool _isLoading = true;
  String _locationError = '';
  ShowLabUserModel? _nearestLab;
  double? _nearestDistance;
  bool _hasLabs = false;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _checkTheme();
  }

  Future<void> _checkTheme() async {
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    setState(() {
      _isDarkMode = brightness == Brightness.dark;
    });
  }

  Future<void> _setMapStyle() async {
    final stylePath = _isDarkMode
        ? 'assets/mapThemes/dark_style.json'
        : 'assets/mapThemes/light_style.json';
    final styleString = await rootBundle.loadString(stylePath);
    _mapController.setMapStyle(styleString);
  }

  Future<void> _initializeData() async {
    await _determinePosition();
    await _loadLabs();
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
      final List<ShowLabUserModel> labs = await _controller.fetchAllLabUsers();
      setState(() {
        _labs = labs;
        _hasLabs = labs.isNotEmpty;
      });

      if (_hasLabs) {
        await _findNearestLab();
        await _updateMarkers();
      }
    } catch (e) {
      setState(() {
        _locationError = 'Failed to load labs. Please try again.';
      });
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
    final rnd = 0.01 * (0.5 - Random().nextDouble());
    return LatLng(
      _currentLocation!.latitude + rnd,
      _currentLocation!.longitude + rnd,
    );
  }

  Future<void> _updateMarkers() async {
    _markers.clear();

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

    for (var lab in _labs) {
      try {
        final labLocation = await _geocodeAddress(lab.userAddress);
        _markers.add(
          Marker(
            markerId: MarkerId(lab.id.toString()),
            position: labLocation,
            icon: lab.id == _nearestLab?.id
                ? await _createCustomIcon(Icons.local_hospital, Colors.green, size: 180.0)
                : await _createCustomIcon(Icons.local_hospital, Colors.green, size: 160.0),
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

  Future<BitmapDescriptor> _createCustomIcon(IconData icon, Color color, {double size = 100.0}) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final textStyle = TextStyle(
      fontSize: size * 0.6,
      fontFamily: icon.fontFamily,
      color: color,
    );

    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: textStyle,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(size * 0.2, size * 0.2));

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<void> _findNearestLab() async {
    if (_currentLocation == null || _labs.isEmpty) {
      setState(() {
        _nearestLab = null;
        _nearestDistance = null;
      });
      return;
    }

    double minDistance = double.infinity;
    ShowLabUserModel? nearestLab;
    double? nearestDistance;

    for (var lab in _labs) {
      try {
        final labLocation = await _geocodeAddress(lab.userAddress);
        final distance = Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          labLocation.latitude,
          labLocation.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearestLab = lab;
          nearestDistance = distance;
        }
      } catch (e) {
        debugPrint("Error calculating distance for ${lab.userName}: $e");
      }
    }

    setState(() {
      _nearestLab = nearestLab;
      _nearestDistance = nearestDistance;
    });
  }

  void _navigateToNearestLab() {
    if (_nearestLab == null || _currentLocation == null) return;

    _geocodeAddress(_nearestLab!.userAddress).then((labLocation) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(labLocation, 14),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        _showLabDetails(_nearestLab!);
      });
    });
  }

  void _showLabDetails(ShowLabUserModel lab) {
    final distance = _nearestLab?.id == lab.id
        ? _nearestDistance
        : Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      _markers.firstWhere((m) => m.markerId.value == lab.id.toString()).position.latitude,
      _markers.firstWhere((m) => m.markerId.value == lab.id.toString()).position.longitude,
    ) /
        1000;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LabUserCard(
                user: lab,
                isDark: _isDarkMode,
                onTap: () {
                  saveEmail(lab.userEmail);
                   saveName(lab.userName);
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShowLabServices(),
                    ),
                  );
                },
              ),
              if (distance != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        distance < 1
                            ? '${(distance * 1000).toStringAsFixed(0)} meters away'
                            : '${distance.toStringAsFixed(1)} Kms away',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Find Labs')),
        body: const Center(child: CircularProgressIndicator()),
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
                  onPressed: _initializeData,
                  child: const Text('Retry'),
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
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _mapController = controller;
              _setMapStyle(); // Apply theme here
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
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
          ),
          Positioned(
            right: 20,
            bottom: 220,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    _mapController.animateCamera(
                      CameraUpdate.zoomIn(),
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    _mapController.animateCamera(
                      CameraUpdate.zoomOut(),
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                if (_hasLabs && _nearestLab != null)
                  FloatingActionButton(
                    heroTag: 'nearest_lab',
                    onPressed: _navigateToNearestLab,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.near_me, color: Colors.white),
                  ),
                if (_hasLabs && _nearestLab != null) const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'my_location',
                  onPressed: () {
                    if (_currentLocation != null) {
                      _mapController.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentLocation!, 14),
                      );
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
