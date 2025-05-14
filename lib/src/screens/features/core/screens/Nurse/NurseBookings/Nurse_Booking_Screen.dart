import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart';
import 'Nurse_Booking_Controller.dart';

class NurseBookingsScreen extends StatelessWidget {
  const NurseBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingControllerNurse>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Requests'),
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
            final booking = controller.activeRequests[index];
            final location = _parseLocation(booking['location']);
            final bids = booking['bids'] as List<dynamic>? ?? [];
            final hasBid = bids.any((bid) =>
            bid['nurseEmail'] == controller.nurse.value?.userEmail);
            final currentBid = hasBid
                ? bids.firstWhere((bid) =>
            bid['nurseEmail'] == controller.nurse.value?.userEmail)
                : null;
            final servicePrice = _getServicePrice(booking['serviceType']);

            final patientLocation = booking['location'] as Map<String, dynamic>? ?? {};
            final Future<double> distanceFuture =
            controller.calculateDistanceBetweenLocations(patientLocation);

            return FutureBuilder<double>(
              future: distanceFuture,
              builder: (context, snapshot) {
                final distance = snapshot.data;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
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
                                  booking['serviceType'] ?? 'Service Request',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildStatusBadge(booking['status']),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.person_outline,
                            'Patient: ${booking['patientEmail'] ?? 'Unknown'}',
                          ),
                          _buildDetailRow(
                            Icons.calendar_today,
                            'Posted: ${_formatDate(booking['createdAt'])}',
                          ),
                          if (location != null)
                            _buildDetailRow(Icons.location_on_outlined, location),
                          if (snapshot.connectionState == ConnectionState.waiting)
                            _buildDetailRow(Icons.directions_walk, 'Calculating distance...'),
                          if (distance != null)
                            _buildDetailRow(Icons.directions_walk,
                                '${distance.toStringAsFixed(2)} km away'),
                          const SizedBox(height: 16),
                          if (hasBid && currentBid != null)
                            _buildCurrentBidCard(currentBid['price']),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            context: context,
                            requestId: booking['_id'].toString(),
                            controller: controller,
                            hasBid: hasBid,
                            currentPrice: currentBid?['price'] ?? servicePrice,
                            serviceName: booking['serviceType'],
                            servicePrice: servicePrice,
                            distance:distance?.toStringAsFixed(2),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      }),
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
    required BookingControllerNurse controller,
    required bool hasBid,
    required double currentPrice,
    required String? serviceName,
    required double servicePrice,
    required String? distance
  }) {
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
          requestId,
          controller,
          hasBid,
          currentPrice,
          serviceName,
          servicePrice,
          distance,
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
      BookingControllerNurse controller,
      bool hasBid,
      double currentPrice,
      String? serviceName,
      double servicePrice,
      String? distance,
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
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).dialogBackgroundColor,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${hasBid ? 'Update' : 'Place'} Bid',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      serviceName ?? 'Service Request',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Enter your bid amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPriceAdjustButton(
                          icon: Icons.remove,
                          onPressed: () {
                            setState(() {
                              currentBid = (currentBid - 100).clamp(servicePrice, servicePrice + 1000);
                              priceController.text = currentBid.toStringAsFixed(0);
                            });
                          }, context: context,
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 140,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                            ),
                            onChanged: (value) {
                              currentBid = double.tryParse(value) ?? servicePrice;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildPriceAdjustButton(
                          icon: Icons.add,
                          onPressed: () {
                            setState(() {
                              currentBid = (currentBid + 100).clamp(servicePrice, servicePrice + 1000);
                              priceController.text = currentBid.toStringAsFixed(0);
                            });
                          }, context: context,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Minimum: PKR ${servicePrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                          ),
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            final price = double.tryParse(priceController.text.trim());
                            if (price == null || price < servicePrice) {
                              Get.snackbar(
                                'Invalid Amount',
                                'Bid must be at least PKR ${servicePrice.toStringAsFixed(0)}',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.red[400],
                                colorText: Colors.white,
                              );
                              return;
                            }

                            final cleanRequestId = _extractObjectId(requestId);
                            final name = await UserRepository.instance
                                .getNurseUserName(email.toString());

                            controller.submitBid(
                                cleanRequestId,
                                price,
                                name ?? "Unknown Nurse",
                                serviceName!,
                                distance!
                            );

                            Navigator.pop(context);
                          },
                          child: Text(
                            hasBid ? 'UPDATE BID' : 'SUBMIT BID',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
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

  Widget _buildPriceAdjustButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        color: Theme.of(context).colorScheme.onSurface,
        onPressed: onPressed,
        splashRadius: 24,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
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
            Icons.assignment_outlined,
            size: 64,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No service requests available',
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

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bidding Information'),
        content: const Text(
          'You can bid on service requests. Patients will choose the best offer.\n\n'
              '• Use +/- buttons to adjust price in PKR 100 increments\n'
              '• Minimum bid is the service base price\n'
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

  double _getServicePrice(String? serviceType) {
    switch (serviceType?.toLowerCase()) {
      case 'blood pressure':
        return 800;
      case 'iv/injection administration':
        return 1500;
      case 'wound dressing':
        return 1200;
      case 'post-operative care':
        return 2500;
      default:
        return 1000;
    }
  }

  String _extractObjectId(String objectIdString) {
    final regex = RegExp(r'ObjectId\("([a-fA-F0-9]+)"\)');
    final match = regex.firstMatch(objectIdString);
    return match != null ? match.group(1)! : objectIdString;
  }
}