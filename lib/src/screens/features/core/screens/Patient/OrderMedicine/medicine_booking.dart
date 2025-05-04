import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientDashboard/patient_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'medical_store_model.dart';
import 'medicne_booking_request_controller.dart';

class MedicalStoreRequestScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedMedicines;

  const MedicalStoreRequestScreen({
    super.key,
    required this.selectedMedicines,
  });

  @override
  _MedicalStoreRequestScreenState createState() => _MedicalStoreRequestScreenState();
}

class _MedicalStoreRequestScreenState extends State<MedicalStoreRequestScreen> {
  final _controller = MedicalStoreController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  String _error = '';
  String? _requestId;
  List<MedicalStoreBid> _bids = [];
  bool _isSearching = true;
  Timer? _bidTimer;
  bool _isResuming = false;
  final _deliveryAddressController = TextEditingController();
  final _notesController = TextEditingController();
  final double _deliveryFee = 50.0;
  File? _prescriptionImage;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadPrescriptionImage();
    await _checkExistingRequest();
  }

  Future<void> _loadPrescriptionImage() async {
    final image = await getPrescriptionImageFromPrefs();
    if (mounted) {
      setState(() {
        _prescriptionImage = image;
      });
    }
  }

  @override
  void dispose() {
    _bidTimer?.cancel();
    _deliveryAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final requestId = prefs.getString('medicalRequestId');

    if (requestId != null && mounted) {
      // Load saved data
      _deliveryAddressController.text = prefs.getString('medicalDeliveryAddress') ?? '';
      _notesController.text = prefs.getString('medicalNotes') ?? '';

      // Check if there's a saved prescription image
      final base64Image = prefs.getString('prescription_image');
      if (base64Image != null) {
        try {
          final bytes = base64Decode(base64Image);
          final tempDir = Directory.systemTemp;
          final file = File('${tempDir.path}/prescription_${DateTime.now().millisecondsSinceEpoch}.png');
          _prescriptionImage = await file.writeAsBytes(bytes);
        } catch (e) {
          debugPrint('Error loading saved prescription image: $e');
        }
      }

      if (mounted) {
        setState(() {
          _requestId = requestId;
          _isLoading = false;
          _isResuming = true;
        });
      }

      _startBidPolling();
    } else {
      await prefs.remove('medicalRequestId');
      await prefs.remove('medicalDeliveryAddress');
      await prefs.remove('medicalNotes');
      await prefs.remove('prescription_image');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveRequestToPrefs() async {
    if (_requestId == null) {
      debugPrint('Error: Attempted to save null request data');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('medicalRequestId', _requestId!);
    await prefs.setString('medicalDeliveryAddress', _deliveryAddressController.text);
    await prefs.setString('medicalNotes', _notesController.text);
    if (_prescriptionImage != null) {
      try {
        final bytes = await _prescriptionImage!.readAsBytes();
        final base64Image = base64Encode(bytes);
        await prefs.setString('prescription_image', base64Image);
      } catch (e) {
        debugPrint('Error saving prescription image: $e');
      }
    }

  }

  Future<void> _clearRequestFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('medicalRequestId');
    await prefs.remove('medicalDeliveryAddress');
    await prefs.remove('medicalNotes');
    await prefs.remove('prescription_image');
  }

  Future<File?> getPrescriptionImageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final base64Image = prefs.getString('prescription_image');

    if (base64Image == null) return null;

    try {
      final bytes = base64Decode(base64Image);
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/prescription_${DateTime.now().millisecondsSinceEpoch}.png');
      return await file.writeAsBytes(bytes);
    } catch (e) {
      debugPrint('Error loading prescription image: $e');
      return null;
    }
  }

  Future<void> _createServiceRequest() async {
    try {
      final patientEmail = _auth.currentUser?.email;
      if (patientEmail == null) throw Exception('User not logged in');
      if (_deliveryAddressController.text.isEmpty) {
        throw Exception('Delivery address is required');
      }

      setState(() => _isLoading = true);

      final requestId = await _controller.createMedicalRequest(
        medicines: widget.selectedMedicines,
        patientEmail: patientEmail,
        deliveryAddress: _deliveryAddressController.text,
        total: _calculateTotal(),
        prescriptionImage: _prescriptionImage,
      );

      setState(() {
        _requestId = requestId;
        _isLoading = false;
      });

      await _saveRequestToPrefs();
      _startBidPolling();
    } catch (e) {
      setState(() {
        _error = 'Failed to create request: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  double _calculateTotal() {
    final subtotal = widget.selectedMedicines.fold<double>(
        0, (sum, item) => sum + (item['price'] as double));
    return subtotal + _deliveryFee;
  }

  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancel'),
        content: const Text('Are you sure you want to cancel this medicine request?'),
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

        await _controller.cancelRequest(_requestId!);
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

  void _startBidPolling() {
    _bidTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_requestId == null) return;

      try {
        final bids = await _controller.fetchBidsForRequest(_requestId!);
        setState(() {
          _bids = bids;
          _isSearching = false;
        });
      } catch (e) {
        print('Error fetching bids: $e');
      }
    });
  }

  Future<void> _acceptBid(MedicalStoreBid bid) async {
    try {
      final patientEmail = _auth.currentUser?.email;
      if (patientEmail == null) throw Exception('User not logged in');

      await _controller.acceptBid(bid.id, patientEmail);
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

  void _showConfirmationDialog(MedicalStoreBid bid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Confirmed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Store: ${bid.storeName ?? 'Unknown Store'}'),
            Text('Bid Amount: PKR ${bid.bidAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            const Text('The store will prepare your order and contact you shortly.'),
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
  Widget build(BuildContext context) {
    if (_isResuming) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resuming previous medicine request...')),
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
        appBar: AppBar(title: const Text('Request Medicines')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Medicines')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _error,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _createServiceRequest,
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
        title: _requestId == null
            ? const Text('Create Request')
            : const Text('Available Bids'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _requestId == null
          ? _buildRequestForm()
          : _isSearching
          ? _buildSearchingUI()
          : _bids.isEmpty
          ? _buildNoBidsUI()
          : _buildBidsList(),
    );
  }

  Widget _buildRequestForm() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary Section
          _buildSectionTitle('Order Summary'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...widget.selectedMedicines.map((medicine) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            medicine['name'],
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        Text(
                          'PKR ${medicine['price']}',
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  )),
                  const Divider(),
                  _buildPriceRow('Subtotal', _calculateTotal() - _deliveryFee),
                  _buildPriceRow('Delivery Fee', _deliveryFee),
                  const Divider(),
                  _buildPriceRow(
                    'Total',
                    _calculateTotal(),
                    isBold: true,
                    textColor: theme.primaryColor,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Prescription Section (if exists)
          if (_prescriptionImage != null) ...[
            _buildSectionTitle('Prescription'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _prescriptionImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Delivery Information Section
          _buildSectionTitle('Delivery Information'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _deliveryAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Address',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your delivery address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes (Optional)',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _createServiceRequest,
              child: const Text(
                'Submit Request',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(
          'Searching for available medical stores...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        const Text(
          'We\'re sending your medicine request to nearby stores',
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
              'Please wait while we connect you with nearby stores',
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
                  leading: const Icon(Icons.local_pharmacy, size: 40),
                  title: Text(bid.storeName ?? 'Unknown Store'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bid Amount: PKR ${bid.bidAmount.toStringAsFixed(2)}'),
                      Text('Original: PKR ${bid.originalAmount.toStringAsFixed(2)}'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(' ${bid.storeRating?.toStringAsFixed(1) ?? 'N/A'}'),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isBold = false, Color? textColor}) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final defaultTextColor = isDarkMode ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor ?? defaultTextColor,
            ),
          ),
          Text(
            'PKR ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor ?? defaultTextColor,
            ),
          ),
        ],
      ),
    );
  }
}