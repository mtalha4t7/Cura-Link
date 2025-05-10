import 'dart:convert';
import 'dart:typed_data';
import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:cura_link/src/screens/features/core/screens/MedicalStore/CheckForRequests/check_for_request_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';


class CheckForRequestsScreen extends StatefulWidget {
  const CheckForRequestsScreen({super.key});


  @override
  State<CheckForRequestsScreen> createState() => _CheckForRequestsScreenState();
}

class _CheckForRequestsScreenState extends State<CheckForRequestsScreen> {

  Uint8List? base64ToImage(String base64String) {

        base64String = base64String;

      return base64Decode(base64String);
;
  }
  @override
  Widget build(BuildContext context) {
    final CheckForRequestsController controller = Get.put(CheckForRequestsController());
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final String? email = FirebaseAuth.instance.currentUser?.email;


    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Requests'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: colors.onPrimary),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.activeRequests.isEmpty) {
          return _buildEmptyState(theme);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.activeRequests.length,
          itemBuilder: (context, index) {
            final request = controller.activeRequests[index];
            final isPrescription = request['requestType'] == 'prescription';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: isPrescription
                  ? _buildPrescriptionRequestCard(context, request, controller)
                  : _buildNonPrescriptionRequestCard(context, request, controller),
            );
          },
        );
      }),
    );
  }
  Future<Map<String, double>> _getPrescriptionDeliveryDetails(
      CheckForRequestsController controller,
      Map<String, dynamic>? patientLocation,
      ) async {
    try {
      final distance = await controller.calculateDistanceBetweenLocations(patientLocation ?? {});
      final fee = await controller.calculateDeliveryFee(patientLocation ?? {});
      return {'distance': distance, 'fee': fee};
    } catch (e) {
      return {
        'distance': 0.0,
        'fee': CheckForRequestsController.MIN_DELIVERY_FEE
      };
    }
  }

  Widget _buildPrescriptionRequestCard(
      BuildContext context,
      Map<String, dynamic> request,
      CheckForRequestsController controller,
      ) {
    final theme = Theme.of(context);
    final patientLocation = request['location'] as Map<String, dynamic>?;
    final prescriptionImage = base64ToImage(request['prescriptionImage']!.toString());

    return FutureBuilder<Map<String, double>>(
      future: _getPrescriptionDeliveryDetails(controller, patientLocation),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final distance = snapshot.data?['distance'] ?? 0.0;
        final deliveryFee = snapshot.data?['fee'] ?? CheckForRequestsController.MIN_DELIVERY_FEE;
         final total=0.00;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: prescriptionImage != null
              ? () => _showFullScreenPrescription(context, prescriptionImage!)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Prescription Request',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    _buildStatusBadge(request['status']?.toString()),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.person_outline,
                  'Patient: ${request['patientEmail'] ?? 'Unknown'}',
                ),
                _buildDetailRow(
                  Icons.calendar_today,
                  'Posted: ${_formatDate(request['createdAt'])}',
                ),
                if (patientLocation != null)
                  _buildDetailRow(
                    Icons.location_on_outlined,
                    _parseLocation(patientLocation) ?? 'Location not available',
                  ),
                _buildDetailRow(
                  Icons.directions_car,
                  'Distance: ${distance.toStringAsFixed(2)} km',
                ),
                if (prescriptionImage != null) ...[
                  const SizedBox(height: 16),
                  const Text('Prescription:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        prescriptionImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.error, color: Colors.red));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to view full prescription',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildBidButton(
                  context,
                  request,
                  controller,
                  deliveryFee,
                  total,
                  isPrescription: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildNonPrescriptionRequestCard(
      BuildContext context,
      Map<String, dynamic> request,
      CheckForRequestsController controller,
      ) {
    final theme = Theme.of(context);
    final patientLocation = request['patientLocation'] as Map<String, dynamic>?;
    final subtotal = (request['subtotal'] as num?)?.toDouble() ?? 0.0;
    final patientEmail=request['patientEmail'];

    return FutureBuilder<Map<String, double>>(
      future: _getDeliveryDetails(controller, patientLocation, subtotal),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final distance = snapshot.data?['distance'] ?? 0.0;
        final deliveryFee = snapshot.data?['fee'] ?? CheckForRequestsController.MIN_DELIVERY_FEE;
        final total = snapshot.data?['total'] ?? subtotal;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Medicine Order',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusBadge(request['status']?.toString()),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.person_outline,
                  'Patient: ${request['patientName'] ?? 'Unknown'}',
                ),
                _buildDetailRow(
                  Icons.location_city,
                  'Address: ${request['deliveryAddress'] ?? 'Address not provided'}',
                ),

                _buildDetailRow(
                  Icons.directions_car,
                  'Distance: ${distance.toStringAsFixed(2)} km',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Order Summary:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._buildMedicineList(request['medicines'] as List<dynamic>?),
                const SizedBox(height: 12),
                _buildPriceDetailRow('Subtotal', subtotal),
                _buildPriceDetailRow('Delivery Fee', deliveryFee),
                _buildPriceDetailRow('Total', total, isTotal: true),
                const SizedBox(height: 16),
                _buildBidButton(context, request, controller, deliveryFee,total),
              ],
            ),
          ),
        );
      },
    );
  }


// Helper function for prescription delivery details
  Future<Map<String, double>> _getDeliveryDetails(
      CheckForRequestsController controller,
      Map<String, dynamic>? patientLocation,
      double subtotal,
      ) async {
    try {
      final distance = await controller.calculateDistanceBetweenLocations(patientLocation ?? {});
      final fee = await controller.calculateDeliveryFee(patientLocation ?? {});
      return {
        'distance': distance,
        'fee': fee,
        'total': subtotal + fee,
      };
    } catch (e) {
      return {
        'distance': 0.0,
        'fee': CheckForRequestsController.MIN_DELIVERY_FEE,
        'total': subtotal,
      };
    }
  }

  Widget _buildBidButton(
      BuildContext context,
      Map<String, dynamic> request,
      CheckForRequestsController controller,
      double deliveryFee,
      double totalPrice, {
        bool isPrescription = false,
      }) {
    final bids = request['bids'] as List<dynamic>? ?? [];
    final hasBid = bids.any((bid) =>
    bid['storeEmail'] == controller.medicalStore.value?.userEmail);
    final currentBid = hasBid
        ? bids.firstWhere((bid) =>
    bid['storeEmail'] == controller.medicalStore.value?.userEmail)
        : null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: hasBid ? Colors.orange : Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        onPressed: () => _showBidDialog(
          context,
          request['_id'].toString(),
          controller,
          hasBid,
          currentBid?['price']?.toDouble() ?? totalPrice,
          isPrescription,
          request['location'],
        ),
        child: Text(
          hasBid ? 'UPDATE BID' : 'PLACE BID',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }




  List<Widget> _buildMedicineList(List<dynamic>? medicines) {
    if (medicines == null || medicines.isEmpty) {
      return [const Text('No medicines specified')];
    }
    return medicines.map((medicine) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.medical_services, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${medicine['name']} (x${medicine['quantity']})',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              'PKR ${medicine['price'].toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPriceDetailRow(String label, dynamic value,
      {bool isTotal = false}) {
    final amount = value is num ? value : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'PKR ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrescriptionBidDialog(BuildContext context,
      String requestId,
      CheckForRequestsController controller,
      bool hasBid,
      double currentPrice,
      String currentDetails,

      ) {
    final priceController = TextEditingController(
      text: currentPrice.toStringAsFixed(0),
    );
    final detailsController = TextEditingController(text: currentDetails);
    final email = FirebaseAuth.instance.currentUser?.email;
    double currentBid = currentPrice;

    showDialog(
      context: context,
      builder: (_) =>
          StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${hasBid ? 'Update' : 'Place'} Prescription Bid',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Enter prescription details:',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: detailsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Enter medicine details, dosage instructions etc.',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Enter your bid amount (PKR)',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPriceAdjustButton(
                              icon: Icons.remove,
                              onPressed: () {
                                setState(() {
                                  currentBid = (currentBid - 50).clamp(
                                      0, double.infinity);
                                  priceController.text =
                                      currentBid.toStringAsFixed(0);
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 120,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                controller: priceController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  prefix: Text('PKR '),
                                ),
                                onChanged: (value) {
                                  currentBid = double.tryParse(value) ?? 0;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildPriceAdjustButton(
                              icon: Icons.add,
                              onPressed: () {
                                setState(() {
                                  currentBid += 50;
                                  priceController.text =
                                      currentBid.toStringAsFixed(0);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('CANCEL'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              onPressed: () async {
                                final price = double.tryParse(
                                    priceController.text.trim());
                                if (price == null || price <= 0) {
                                  Get.snackbar(
                                    'Invalid Amount',
                                    'Please enter a valid bid amount',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red[400],
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                if (detailsController.text
                                    .trim()
                                    .isEmpty) {
                                  Get.snackbar(
                                    'Missing Details',
                                    'Please enter prescription details',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red[400],
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                final cleanRequestId = _extractObjectId(
                                    requestId);
                                final name = await UserRepository.instance
                                    .getMedicalStoreUserName(email.toString());

                                // Get the current request to access prescription image
                                final request = controller.activeRequests.firstWhere(
                                      (req) => req['_id'].toString().contains(cleanRequestId),
                                  orElse: () => {},
                                );

                                controller.submitBid(
                                  cleanRequestId,
                                  price,
                                  name ?? "Unknown Store",
                                  prescriptionDetails: detailsController.text
                                      .trim(),
                                  prescriptionImage: request['prescriptionImage'],
                                  patientEmail: request['patientEmail'],
                                );

                                Navigator.pop(context);
                              },
                              child: const Text('SUBMIT'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
  void _showFullScreenPrescription(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            PhotoView(
              imageProvider: MemoryImage(imageBytes),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(
                    Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPriceAdjustButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      shape: const CircleBorder(),
      color: Colors.grey[100],
      child: IconButton(
        icon: Icon(icon, color: Colors.grey[800]),
        onPressed: onPressed,
        splashRadius: 24,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_pharmacy_outlined,
            size: 64,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No medicine requests available',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new requests',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        (status ?? 'pending').toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }



  void _showBidDialog(
      BuildContext context,
      String requestId,
      CheckForRequestsController controller,
      bool hasBid,
      double currentPrice,
      bool isPrescription,
      dynamic location,
      ) {
    final priceController = TextEditingController(
      text: currentPrice.toStringAsFixed(0),
    );
    final email = FirebaseAuth.instance.currentUser?.email;
    double currentBid = currentPrice;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${hasBid ? 'Update' : 'Place'} ${isPrescription ? 'Prescription ' : ''}Bid',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isPrescription) ...[
                    const Text(
                      'Enter prescription details:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter medicine details, dosage instructions etc.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    'Enter your bid amount (PKR)',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPriceAdjustButton(
                        icon: Icons.remove,
                        onPressed: () {
                          setState(() {
                            currentBid = (currentBid - 50).clamp(0, double.infinity);
                            priceController.text = currentBid.toStringAsFixed(0);
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            prefix: Text('PKR '),
                          ),
                          onChanged: (value) {
                            currentBid = double.tryParse(value) ?? currentPrice;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildPriceAdjustButton(
                        icon: Icons.add,
                        onPressed: () {
                          setState(() {
                            currentBid += 50;
                            priceController.text = currentBid.toStringAsFixed(0);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: () async {
                          final price = double.tryParse(priceController.text.trim());
                          if (price == null || price <= 0) {
                            Get.snackbar(
                              'Invalid Amount',
                              'Please enter a valid bid amount',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red[400],
                              colorText: Colors.white,
                            );
                            return;
                          }

                          final cleanRequestId = _extractObjectId(requestId);
                          final name = await UserRepository.instance
                              .getMedicalStoreUserName(email.toString());

                          controller.submitBid(
                            cleanRequestId,
                            price,
                            name ?? "Unknown Store",
                          );

                          Navigator.pop(context);
                        },
                        child: const Text('SUBMIT'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text('Bidding Information'),
            content: const Text(
              'You can bid on medicine requests. Patients will choose the best offer.\n\n'
                  '• Use +/- buttons to adjust price in PKR 50 increments\n'
                  '• Minimum bid is the medicine base price\n'
                  '• You can update your bid anytime before acceptance',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('GOT IT'),
              ),
            ],
          ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown date';
    try {
      final dateTime = date is DateTime ? date : DateTime.parse(
          date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  String? _parseLocation(dynamic locationData) {
    if (locationData == null) return null;
    if (locationData is String) return locationData;
    if (locationData is Map) return locationData['address']?.toString();
    return null;
  }

  double _getMedicinePrice(String? medicineType) {
    switch (medicineType?.toLowerCase()) {
      case 'antibiotics':
        return 500;
      case 'painkillers':
        return 300;
      case 'chronic medication':
        return 800;
      case 'specialty drugs':
        return 1500;
      default:
        return 400;
    }
  }

  String _extractObjectId(String objectIdString) {
    final regex = RegExp(r'ObjectId\("([a-fA-F0-9]+)"\)');
    final match = regex.firstMatch(objectIdString);
    return match != null ? match.group(1)! : objectIdString;
  }
}