import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'Nurse_Booking_Controller.dart';

class NurseBookingsScreen extends StatelessWidget {
  const NurseBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingControllerNurse>();
    print('🏥 Building NurseBookingsScreen...');

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: Obx(() {
        print('🔄 Rebuilding UI - Loading: ${controller.isLoading.value}');
        print('   📚 Active requests count: ${controller.activeRequests.length}');

        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.activeRequests.isEmpty) {
          print('⚠️ No active requests to display');
          return const Center(child: Text('No bookings found'));
        }

        return ListView.builder(
          itemCount: controller.activeRequests.length,
          itemBuilder: (context, index) {
            final booking = controller.activeRequests[index];
            print('🖨️ Rendering booking item $index: ${booking['_id']}');

            final bids = booking['bids'] as List<dynamic>? ?? [];
            final hasBid = bids.any((bid) =>
            bid['nurseEmail'] == controller.nurse.value?.userEmail);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['serviceType'] ?? 'Unknown Service',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text('Patient: ${booking['patientEmail'] ?? 'Unknown'}'),
                    Text('Status: ${booking['status']?.toUpperCase() ?? 'UNKNOWN'}'),
                    if (booking['price'] != null)
                      Text('Price: \$${booking['price'].toStringAsFixed(2)}'),
                    const SizedBox(height: 6),
                    Text(
                      hasBid
                          ? '✅ You have already submitted a bid.'
                          : '⚠️ You have not bid on this request yet.',
                      style: TextStyle(
                        color: hasBid ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: hasBid
                          ? null
                          : () {
                        _showBidDialog(context, booking['_id'].toString(), controller);
                      },
                      child: Text(hasBid ? 'Bid Submitted' : 'Bid Now'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showBidDialog(BuildContext context, String requestId, BookingControllerNurse controller) {
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit Your Bid'),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Enter your price'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text.trim());
              if (price != null) {
                controller.submitBid(requestId, price);
                Navigator.of(context).pop();
              } else {
                Get.snackbar('Error', 'Please enter a valid number');
              }
            },
            child: const Text('Submit Bid'),
          ),
        ],
      ),
    );
  }
}
