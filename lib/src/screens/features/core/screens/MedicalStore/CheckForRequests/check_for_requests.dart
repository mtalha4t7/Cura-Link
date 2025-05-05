import 'package:cached_network_image/cached_network_image.dart';
import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:cura_link/src/screens/features/core/screens/MedicalStore/CheckForRequests/check_for_request_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:photo_view/photo_view.dart';


class CheckForRequestsScreen extends StatefulWidget {
  const CheckForRequestsScreen({super.key});


  @override
  State<CheckForRequestsScreen> createState() => _CheckForRequestsScreenState();
}

class _CheckForRequestsScreenState extends State<CheckForRequestsScreen> {

  @override
  Widget build(BuildContext context) {
    final CheckForRequestsController controller = Get.put(CheckForRequestsController());
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
                  : _buildNonPrescriptionRequestCard(
                  context, request, controller),
            );
          },
        );
      }),
    );
  }

  Widget _buildPrescriptionRequestCard(BuildContext context,
      Map<String, dynamic> request, CheckForRequestsController controller) {
    final theme = Theme.of(context);
    final location = _parseLocation(request['location']);
    final bids = request['bids'] as List<dynamic>? ?? [];
    final hasBid = bids.any((bid) =>
    bid['storeEmail'] == controller.medicalStore.value?.userEmail);
    final currentBid = hasBid
        ? bids.firstWhere((bid) =>
    bid['storeEmail'] == controller.medicalStore.value?.userEmail)
        : null;
    final prescriptionImage = request['prescriptionImage'];

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (prescriptionImage != null) {
          _showFullScreenPrescription(context, prescriptionImage);
        }
      },
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildStatusBadge(request['status']),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.person_outline,
                'Patient: ${request['patientEmail'] ?? 'Unknown'}'),
            _buildDetailRow(Icons.calendar_today,
                'Posted: ${_formatDate(request['createdAt'])}'),
            if (location != null)
              _buildDetailRow(Icons.location_on_outlined, location),

            // Prescription Image Preview
            if (prescriptionImage != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Prescription:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: prescriptionImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                    const Icon(Icons.error),
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
            if (hasBid && currentBid != null)
              _buildCurrentBidCard(currentBid['price']),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: hasBid ? Colors.orange : theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () =>
                    _showPrescriptionBidDialog(
                      context,
                      request['_id'].toString(),
                      controller,
                      hasBid,
                      currentBid?['price'] ?? 0,
                      currentBid?['prescriptionDetails'] ?? '',
                    ),
                child: Text(
                  hasBid ? 'UPDATE BID' : 'PLACE BID',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNonPrescriptionRequestCard(BuildContext context,
      Map<String, dynamic> request, CheckForRequestsController controller) {
    final theme = Theme.of(context);
    final location = _parseLocation(request['location']);
    final bids = request['bids'] as List<dynamic>? ?? [];
    final hasBid = bids.any((bid) =>
    bid['storeEmail'] == controller.medicalStore.value?.userEmail);
    final currentBid = hasBid
        ? bids.firstWhere((bid) =>
    bid['storeEmail'] == controller.medicalStore.value?.userEmail)
        : null;
    final totalPrice = request['total'] ?? 0.0;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {},
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
                _buildStatusBadge(request['status']),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.person_outline,
                'Patient: ${request['patientEmail'] ?? 'Unknown'}'),
            _buildDetailRow(Icons.calendar_today,
                'Posted: ${_formatDate(request['createdAt'])}'),
            if (location != null)
              _buildDetailRow(Icons.location_on_outlined, location),

            // Order Summary
            const SizedBox(height: 16),
            const Text(
              'Order Summary:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._buildMedicineList(request['medicines']),
            const SizedBox(height: 12),
            _buildPriceDetailRow('Subtotal', request['subtotal']),
            _buildPriceDetailRow('Delivery Fee', request['deliveryFee']),
            _buildPriceDetailRow('Total', request['total'], isTotal: true),
            const SizedBox(height: 16),
            if (hasBid && currentBid != null)
              _buildCurrentBidCard(currentBid['price']),
            const SizedBox(height: 12),
            _buildActionButton(
              context: context,
              requestId: request['_id'].toString(),
              controller: controller,
              hasBid: hasBid,
              currentPrice: currentBid?['price'] ?? totalPrice,
              medicineName: 'Medicine Order',
              medicinePrice: totalPrice,
            ),
          ],
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
      String currentDetails,) {
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

                                controller.submitBid(
                                  cleanRequestId,
                                  price,
                                  name ?? "Unknown Store",
                                  prescriptionDetails: detailsController.text
                                      .trim(),
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

  void _showFullScreenPrescription(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) =>
          Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(0),
            child: Stack(
              children: [
                PhotoView(
                  imageProvider: NetworkImage(imageUrl),
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

  Widget _buildCurrentBidCard(double price) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR CURRENT BID',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PKR ${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String requestId,
    required CheckForRequestsController controller,
    required bool hasBid,
    required double currentPrice,
    required String? medicineName,
    required double medicinePrice,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: hasBid ? Colors.orange : Theme
              .of(context)
              .primaryColor,
          foregroundColor: Colors.white,
        ),
        onPressed: () =>
            _showBidDialog(
              context,
              requestId,
              controller,
              hasBid,
              currentPrice,
              medicineName,
              medicinePrice,
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

  void _showBidDialog(
      BuildContext context,
      String requestId,
      CheckForRequestsController controller,
      bool hasBid,
      double currentPrice,
      String? medicineName,
      double medicinePrice,
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
                    '${hasBid ? 'Update' : 'Place'} Bid',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    medicineName ?? 'Medicine Request',
                    style: Theme.of(context).textTheme.bodyMedium,
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
                            currentBid = (currentBid - 50).clamp(medicinePrice, double.infinity);
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
                            currentBid = double.tryParse(value) ?? medicinePrice;
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
                  const SizedBox(height: 8),
                  Text(
                    'Medicine base price: PKR ${medicinePrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
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
                          if (price == null || price < medicinePrice) {
                            Get.snackbar(
                              'Invalid Amount',
                              'Bid must be at least PKR ${medicinePrice.toStringAsFixed(0)}',
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