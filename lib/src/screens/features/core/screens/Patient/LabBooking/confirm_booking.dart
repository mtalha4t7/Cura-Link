import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../notification_handler/notification_server.dart';


class BookingConfirmationScreen extends StatelessWidget {
  final String labName;
  final String bookingId;
  final DateTime bookingTime;
  final String recipientUserId;

  const BookingConfirmationScreen({
    super.key,
    required this.labName,
    required this.bookingId,
    required this.bookingTime,
    required this.recipientUserId,
  });

  Future<void> _confirmBooking() async {
    try {
      // 1. Perform your booking confirmation logic here

      // 2. Send notification
      await NotificationService().sendBookingConfirmation(
        recipientUserId: recipientUserId,
        labName: labName,
        bookingId: bookingId,
        bookingTime: bookingTime,
      );

      // 3. Show success message
      Get.snackbar('Success', 'Booking confirmed and notification sent');

    } catch (e) {
      Get.snackbar('Error', 'Failed to confirm booking: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Confirm booking at $labName'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _confirmBooking,
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}