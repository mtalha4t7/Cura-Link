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
    return base64Decode(base64String);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CheckForRequestsController());
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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

  Widget _buildPrescriptionRequestCard(
      BuildContext context,
      Map<String, dynamic> request,
      CheckForRequestsController controller,
      ) {
    final prescriptionImage = base64ToImage(request['prescriptionImage']?.toString() ?? '');
    final patientLocation = request['patientLocation'] as Map<String, dynamic>?;

    return FutureBuilder<Map<String, double>>(
      future: controller.getDeliveryDetails(patientLocation ?? {}),
      builder: (context, snapshot) {
        final distance = snapshot.data?['distance'] ?? 0.0;
        final deliveryFee = snapshot.data?['fee'] ?? CheckForRequestsController.MIN_DELIVERY_FEE;
        final basePrice = (request['basePrice'] as num?)?.toDouble() ?? 0.0;
        final totalPrice = basePrice + deliveryFee;

        return Padding(
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
                  request['deliveryAddress'] ?? 'Location not available',
                ),
              _buildDetailRow(
                Icons.directions_car,
                'Distance: ${distance.toStringAsFixed(2)} km',
              ),
              _buildDetailRow(
                Icons.local_shipping,
                'Delivery Fee: PKR ${deliveryFee.toStringAsFixed(2)}',
              ),
              if (prescriptionImage != null) ...[
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _showFullScreenPrescription(context, prescriptionImage!),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildBidButton(
                context,
                request,
                controller,
                deliveryFee,
                totalPrice,
                true, // isPrescription
              ),
            ],
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
    final patientLocation = request['patientLocation'] as Map<String, dynamic>?;
    final subtotal = (request['subtotal'] as num?)?.toDouble() ?? 0.0;

    return FutureBuilder<Map<String, double>>(
      future: controller.getDeliveryDetails(patientLocation ?? {}),
      builder: (context, snapshot) {
        final deliveryFee = snapshot.data?['fee'] ?? CheckForRequestsController.MIN_DELIVERY_FEE;
        final double totalPrice = subtotal + deliveryFee;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Medicine Order',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                Icons.location_on_outlined,
                'Address: ${request['deliveryAddress'] ?? 'Address not provided'}',
              ),
              _buildDetailRow(
                Icons.directions_car,
                'Distance: ${(snapshot.data?['distance'] ?? 0.0).toStringAsFixed(2)} km',
              ),
              _buildDetailRow(
                Icons.local_shipping,
                'Delivery Fee: PKR ${deliveryFee.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 16),
              ..._buildMedicineList(request['medicines'] as List<dynamic>?),
              const SizedBox(height: 12),
              _buildPriceDetailRow('Subtotal', subtotal),
              _buildPriceDetailRow('Total', totalPrice, isTotal: true),
              const SizedBox(height: 16),
              _buildBidButton(
                context,
                request,
                controller,
                deliveryFee,
                totalPrice,
                false, // isPrescription
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBidButton(
      BuildContext context,
      Map<String, dynamic> request,
      CheckForRequestsController controller,
      double deliveryFee,
      double totalPrice,
      bool isPrescription,
      ) {
    final bids = request['bids'] as List<dynamic>? ?? [];
    final hasBid = bids.any((bid) => bid['storeEmail'] == controller.medicalStore.value?.userEmail);
    final currentBid = hasBid ? bids.firstWhere((bid) => bid['storeEmail'] == controller.medicalStore.value?.userEmail) : null;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: hasBid ? Colors.orange : Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () => isPrescription
          ? _showPrescriptionBidDialog(
        context,
        request['patientEmail'].toString(),
        request['_id'].toString(),
        controller,
        hasBid,
        currentBid?['basePrice']?.toDouble() ?? 0.0,
        deliveryFee,
        currentBid?['prescriptionDetails']?.toString() ?? '',
        request['patientLocation'],
      )
          : _showNonPrescriptionBidDialog(
        context,
        request['patientEmail'].toString(),
        request['_id'].toString(),
        request['medicines'],
        controller,
        hasBid,
        (currentBid?['basePrice']?.toDouble() ?? (request['subtotal']?.toDouble() ?? 0.0)),
        deliveryFee,
        request['patientLocation'],
      ),
      child: Text(hasBid ? 'UPDATE BID' : 'PLACE BID'),
    );
  }

  void _showPrescriptionBidDialog(
      BuildContext context,
      String patientEmail,
      String requestId,
      CheckForRequestsController controller,
      bool hasBid,
      double currentBasePrice,
      double deliveryFee,
      String currentDetails,
      dynamic location,
      ) {
    final basePriceController = TextEditingController(text: currentBasePrice.toStringAsFixed(2));
    final detailsController = TextEditingController(text: currentDetails);
    bool includeDelivery = true;
    double totalPrice = currentBasePrice + deliveryFee;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('${hasBid ? 'Update' : 'Place'} Prescription Bid'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: detailsController,
                    decoration: const InputDecoration(
                      labelText: 'Prescription Details',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: basePriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Base Price (PKR)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final base = double.tryParse(value) ?? 0.0;
                      setState(() => totalPrice = base + (includeDelivery ? deliveryFee : 0));
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                        value: includeDelivery,
                        onChanged: (value) {
                          setState(() {
                            includeDelivery = value!;
                            totalPrice = (double.tryParse(basePriceController.text) ?? 0.0) +
                                (includeDelivery ? deliveryFee : 0);
                          });
                        },
                      ),
                       Text('Delivery Fee (PKR ${deliveryFee.toStringAsFixed(2)})'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Total Bid Price: PKR ${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final basePrice = double.tryParse(basePriceController.text) ?? 0.0;
                  final total = basePrice + (includeDelivery ? deliveryFee : 0);

                  if (basePrice <= 0) {
                    Get.snackbar('Error', 'Please enter a valid base price');
                    return;
                  }

                  final cleanRequestId = _extractObjectId(requestId);
                  final name = await UserRepository.instance.getMedicalStoreUserName(
                      FirebaseAuth.instance.currentUser!.email!
                  );

                  controller.submitBid(
                    cleanRequestId,
                    patientEmail,
                    includeDelivery ? deliveryFee : 0,
                    total,
                    basePrice,
                    name ?? "Unknown Store",
                    prescriptionDetails: detailsController.text,

                  );

                  Navigator.pop(context);
                },
                child: const Text('Submit Bid'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNonPrescriptionBidDialog(
      BuildContext context,
      String patientEmail,
      String requestId,
      List<dynamic> medicines,
      CheckForRequestsController controller,
      bool hasBid,
      double currentBasePrice,
      double deliveryFee,
      dynamic location,
      ) {
    final basePriceController = TextEditingController(text: currentBasePrice.toStringAsFixed(2));
    bool includeDelivery = true;
    double totalPrice = currentBasePrice + deliveryFee;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${hasBid ? 'Update' : 'Place'} Medicine Bid',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Close',
                        ),
                      ],
                    ),

                    const Divider(height: 30, thickness: 1),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Base Price Input
                            Text(
                              'Base Price (PKR)',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: basePriceController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'Enter base price',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              onChanged: (value) {
                                final base = double.tryParse(value) ?? 0.0;
                                setState(() => totalPrice = base + (includeDelivery ? deliveryFee : 0));
                              },
                            ),

                            const SizedBox(height: 20),

                            // Delivery Fee Toggle
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Transform.scale(
                                    scale: 1.2,
                                    child: Checkbox(
                                      value: includeDelivery,
                                      onChanged: (value) {
                                        setState(() {
                                          includeDelivery = value!;
                                          totalPrice = (double.tryParse(basePriceController.text) ?? 0.0) +
                                              (includeDelivery ? deliveryFee : 0);
                                        });
                                      },
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Delivery Fee: PKR ${deliveryFee.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Total Price Display
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Bid Amount',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PKR ${totalPrice.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final basePrice = double.tryParse(basePriceController.text) ?? 0.0;
                            final total = basePrice + (includeDelivery ? deliveryFee : 0);

                            final cleanRequestId = _extractObjectId(requestId);
                            final name = await UserRepository.instance.getMedicalStoreUserName(
                                FirebaseAuth.instance.currentUser!.email!
                            );

                            controller.submitBid(
                              cleanRequestId,
                              patientEmail,
                              includeDelivery ? deliveryFee : 0,
                              total,
                              basePrice,
                              name ?? "Unknown Store",
                              medicines: medicines,
                            );

                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Submit Bid'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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

  Widget _buildPriceDetailRow(String label, dynamic value, {bool isTotal = false}) {
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
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
      final dateTime = date is DateTime ? date : DateTime.parse(date.toString());
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

  String _extractObjectId(String objectIdString) {
    final regex = RegExp(r'ObjectId\("([a-fA-F0-9]+)"\)');
    final match = regex.firstMatch(objectIdString);
    return match != null ? match.group(1)! : objectIdString;
  }
}