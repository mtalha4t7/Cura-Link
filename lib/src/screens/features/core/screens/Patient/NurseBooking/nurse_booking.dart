import 'dart:async';
import 'package:bson/bson.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/NurseBooking/nurse_booking_controller.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientDashboard/patient_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../notification_handler/send_notification.dart';
import '../../../../../../stripe/stripe_services.dart';
import 'bid_model.dart';

class NurseBookingScreen extends StatefulWidget {
  final String selectedServiceName;
  final String selectedServicePrice;

  const NurseBookingScreen({
    super.key,
    required this.selectedServiceName,
    required this.selectedServicePrice
  });

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
 final  isAccepting = false.obs;



  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  @override
  void dispose() {
    _bidTimer?.cancel();
    super.dispose();
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

      final availableNurses = await MongoDatabase.getAvailableNurses();
      if (availableNurses != null) {
        for (var nurse in availableNurses) {
          final deviceToken = nurse['userDeviceToken'];
          final userName = nurse['userName'];
          if (deviceToken != null && deviceToken.isNotEmpty) {
            await SendNotificationService.sendNotificationUsingApi(
              token: deviceToken,
              title: "$userName check New Booking Request",
              body: "Someone has requested a service. Tap to bid!",
              data: {"screen": "NurseBookingsScreen"},
            );
          }
        }
      }
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

      final requestId = await _controller.createServiceRequest(
        serviceType: widget.selectedServiceName,
        location: _currentLocation!,
        patientEmail: patientEmail,
        price: widget.selectedServicePrice,
      );

      final availableNurses = await MongoDatabase.getAvailableNurses();
      if (availableNurses != null) {
        for (var nurse in availableNurses) {
          final deviceToken = nurse['userDeviceToken'];
          final userName = nurse['userName'];
          if (deviceToken != null && deviceToken.isNotEmpty) {
            await SendNotificationService.sendNotificationUsingApi(
              token: deviceToken,
              title: "$userName check New Booking Request",
              body: "Someone has requested a service. Tap to bid!",
              data: {"screen": "NurseBookingsScreen"},
            );
          }
        }
      }

      setState(() => _requestId = requestId);
      await _saveRequestToPrefs();
    } catch (e) {
      setState(() {
        _locationError = 'Failed to create request: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveRequestToPrefs() async {
    if (_requestId == null || _currentLocation == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nurseRequestId', _requestId!);
    await prefs.setString('nurseService', widget.selectedServiceName);
    await prefs.setString('nurseServicePrice', widget.selectedServicePrice);
    await prefs.setDouble('requestLat', _currentLocation!.latitude);
    await prefs.setDouble('requestLng', _currentLocation!.longitude);
  }

  Future<void> _clearRequestFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nurseRequestId');
    await prefs.remove('nurseService');
    await prefs.remove('nurseServicePrice');
    await prefs.remove('requestLat');
    await prefs.remove('requestLng');
  }

  void _startBidPolling() {
    _bidTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_requestId == null) return;

      try {
        final bids = await _controller.fetchBids(_requestId!);
        setState(() {
          _bids = bids;
          _isSearching = false;
        });
      } catch (e) {
        print('Error fetching bids: $e');
      }
    });
  }



  Future<void> _acceptBid(Bid bid) async {
    try {


        final patientEmail = FirebaseAuth.instance.currentUser?.email.toString();
        if (patientEmail == null) throw Exception('User not logged in');

        await NurseBookingController.acceptBid(bid.id, patientEmail);
        await _clearRequestFromPrefs();


        _showConfirmationDialog(bid);

    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to complete booking: ${e.toString()}'),
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Booking Confirmed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nurse: ${bid.nurseName ?? 'Unknown'}'),
            Text('Service: ${bid.serviceName}'),
            Text('Amount: \$${bid.price.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('The nurse will contact you shortly.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              Get.offAll(() => PatientDashboard());
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancel'),
        content: const Text('Are you sure you want to cancel the nurse request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
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
                  Navigator.pop(context, false);
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
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? const Text('Request Nurse Service')
              : const Text('Available Bids'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_locationError.isNotEmpty) {
      return Center(
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
      );
    }

    return _isSearching ? _buildSearchingUI() :
    _bids.isEmpty ? _buildNoBidsUI() : _buildBidsList();
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
          'We\'re sending your request for "${widget.selectedServiceName}"',
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
                      Text('Service: ${bid.serviceName}'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(' ${bid.rating?.toStringAsFixed(1) ?? 'N/A'}'),
                        ],
                      ),
                    ],
                  ),
                  trailing: Obx(() => ElevatedButton(
                    onPressed: isAccepting.value ? null : () async {
                      isAccepting(true);
                      try {
                        await _acceptBid(bid);  // Your accept logic
                      } finally {
                        isAccepting(false);
                      }
                    },
                    child: isAccepting.value
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('Accept'),
                  ))

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