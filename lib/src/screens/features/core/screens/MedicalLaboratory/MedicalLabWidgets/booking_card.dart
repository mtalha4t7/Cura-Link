import 'package:flutter/material.dart';

class BookingCard extends StatelessWidget {
  final String patientName;
  final String testName;
  final String bookingDate;
  final String status;
  final bool isDark;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onModify;

  const BookingCard({
    super.key,
    required this.patientName,
    required this.testName,
    required this.bookingDate,
    required this.status,
    required this.isDark,
    required this.onAccept,
    required this.onReject,
    required this.onModify,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient: $patientName',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Test: $testName',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Date: $bookingDate',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: $status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: statusColor(status, isDark),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: onAccept,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.green),
                  ),
                  child: const Text('Accept'),
                ),
                ElevatedButton(
                  onPressed: onReject,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.red),
                  ),
                  child: const Text('Reject'),
                ),
                ElevatedButton(
                  onPressed: onModify,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.blue),
                  ),
                  child: const Text('Modify'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color statusColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return isDark ? Colors.orangeAccent : Colors.orange;
      default:
        return isDark ? Colors.white70 : Colors.black54;
    }
  }
}
