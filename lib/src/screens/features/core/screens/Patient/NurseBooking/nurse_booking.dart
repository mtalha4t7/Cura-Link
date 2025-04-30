import 'dart:async';
import 'package:bson/bson.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/NurseBooking/nurse_booking_controller.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientDashboard/patient_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nurseModel.dart';
import 'temp_user_NurseModel.dart';
import 'bid_model.dart';

class NurseBookingScreen extends StatefulWidget {
  final String selectedService;

  const NurseBookingScreen({super.key, required this.selectedService});

  @override
  _NurseBookingScreenState createState() => _NurseBookingScreenState();
}

class _NurseBookingScreenState extends State<NurseBookingScreen> {
  final _controller = NurseBookingController();
  LatLng? _currentLocation;
  bool _isLoading = true;
  String _locationError = '';
  String? _requestId;
  List<Bid> _bids = [];
  bool _isSearching = true;
  Timer? _bidTimer;
  bool _isResuming = false;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  Future<void> _checkExistingRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final requestId = prefs.getString('nurseRequestId');
    final savedLat = prefs.getDouble('requestLat');
    final savedLng = prefs.getDouble('requestLng');

    if (requestId != null && savedLat != null && savedLng != null && mounted) {
      setState(() {
        _requestId = requestId;
        _currentLocation = LatLng(savedLat, savedLng);
        _isLoading = false;
        _isResuming = true;
      });
      _startBidPolling();
    } else {
      await prefs.remove('nurseRequestId');
      await prefs.remove('requestLat');
      await prefs.remove('requestLng');
      await _initializeData();
    }
  }

  Future<void> _initializeData() async {
    await _determinePosition();
    if (_currentLocation != null) {
      await _createServiceRequest();
      _startBidPolling();
    }
  }

  Future<void> _saveRequestToPrefs() async {
    if (_requestId == null || _currentLocation == null) {
      debugPrint('Error: Attempted to save null request data');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nurseRequestId', _requestId!);
    await prefs.setString('nurseService', widget.selectedService);
    await prefs.setDouble('requestLat', _currentLocation!.latitude);
    await prefs.setDouble('requestLng', _currentLocation!.longitude);
  }

  Future<void> _clearRequestFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nurseRequestId');
    await prefs.remove('nurseService');
    await prefs.remove('requestLat');
    await prefs.remove('requestLng');
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationError = 'Location services are disabled');
      return;
    }

    permission = await Geolocator.checkPermission();
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
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Error getting location: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _createServiceRequest() async {
    if (_currentLocation == null) {
      setState(() {
        _locationError = 'Location services are required';
        _isLoading = false;
      });
      return;
    }

    try {
      final patientEmail = FirebaseAuth.instance.currentUser?.email;
      if (patientEmail == null) throw Exception('User not logged in');

      // Call controller to create request (MongoDB auto-generates _id)
      final requestId = await _controller.createServiceRequest(
        serviceType: widget.selectedService,
        location: _currentLocation!,
        patientEmail: patientEmail,
      );

      // Save the Mongo ObjectId (hex string)
      setState(() => _requestId = requestId);
      await _saveRequestToPrefs();
    } catch (e) {
      setState(() {
        _locationError = 'Failed to create request: ${e.toString()}';
        _isLoading = false;
      });
    }
  }


  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancel'),
        content: const Text('Are you sure you want to cancel the nurse request?'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: Colors.grey.withOpacity(0.1),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No', style: TextStyle(fontSize: 16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: Colors.red.withOpacity(0.1),
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Cancel', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      _bidTimer?.cancel();
      if (_requestId != null) {
        await _controller.cancelServiceRequest(_requestId!);
        await _clearRequestFromPrefs();
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to cancel request: ${e.toString()}'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }


  void _startBidPolling() {
    _bidTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_requestId == null) return;

      try {
        final bids = await _controller.fetchBids(_requestId!);
        print("==========================="+bids.toString());
        final nurseEmails = bids.map((b) => b.nurseEmail).toList();
        final nurseNamse=bids.map((b)=>b.nurseName).toString();
        final nurses = await _controller.getNurseDetails(nurseEmails);
        print(nurseEmails);

        setState(() {
          _bids = bids.map((bid) {
            final nurse = nurses.firstWhere(
                  (n) => n.userEmail == bid.nurseEmail,
              orElse: () => Nurse(userName: nurseNamse??'Unknown', userEmail: '', id: ''),
            );

            return bid..nurseName = nurse.userName;
          }).toList();
          _isSearching = false;
        });
      } catch (e) {
        print('Error fetching bids: $e');
      }
    });
  }

  Future<void> _acceptBid(Bid bid) async {
    try {
      await _controller.acceptBid(bid.id);
      await _clearRequestFromPrefs();
      _showConfirmationDialog(bid);
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to accept bid: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showConfirmationDialog(Bid bid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Confirmed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nurse: ${bid.nurseName}'),
            Text('Price: \$${bid.price.toStringAsFixed(2)}'),
            if (bid.rating != null)
              Text('Rating: ${bid.rating!.toStringAsFixed(1)}/5'),
            const SizedBox(height: 10),
            const Text('The nurse will contact you shortly.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bidTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isResuming) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resuming previous nurse request...')),
        );
        _isResuming = false;
      });
    }

    return WillPopScope(
      onWillPop: () async {
        if (_requestId == null) return true;

        final shouldCancel = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Active Request'),
            content: const Text('Keep request running in background?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false); // Minimize
                  Get.to(() => PatientDashboard());

                },
                child: const Text('Minimize'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cancel Request'),
              ),
            ],
          ),
        );

        if (shouldCancel ?? false) {
          await _cancelRequest();
        }
        return shouldCancel ?? false;
      },
      child: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Nurse Service')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_locationError.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Nurse Service')),
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
        title: const Text('Available Bids'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSearching
          ? _buildSearchingUI()
          : _bids.isEmpty
          ? _buildNoBidsUI()
          : _buildBidsList(),
    );
  }

  Widget _buildSearchingUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(
          'Searching for available nurses...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Text(
          'We\'re sending your request for "${widget.selectedService}"',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          icon: const Icon(Icons.cancel),
          label: const Text('Cancel Request'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: _cancelRequest,
        ),
      ],
    );
  }

  Widget _buildNoBidsUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 60, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              'No bids received yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            const Text(
              'Please wait while we connect you with nearby nurses',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: _cancelRequest,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBidsList() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _bids.length,
            itemBuilder: (context, index) {
              final bid = _bids[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.medical_services, size: 40),
                  title: Text(bid.nurseName ?? 'Unknown Nurse'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Price: \$${bid.price.toStringAsFixed(2)}'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(' ${bid.rating?.toStringAsFixed(1) ?? 'N/A'}'),
                        ],
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _acceptBid(bid),
                    child: const Text('Accept'),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: _cancelRequest,
          ),
        ),
      ],
    );
  }
}
