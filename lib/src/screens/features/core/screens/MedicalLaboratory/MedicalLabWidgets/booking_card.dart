import 'package:flutter/material.dart';

class BookingCard extends StatelessWidget {
  final String patientName;
  final String testName;
  final String bookingDate;
  final String status;
  final String price;
  final bool isDark;
  final bool showAcceptButton;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onModify;

  const BookingCard({
    super.key,
    required this.patientName,
    required this.testName,
    required this.bookingDate,
    required this.status,
    required this.price,
    required this.isDark,
    required this.showAcceptButton,
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
              'Price: \$$price',
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

            if (status == 'Pending' || status == 'Modified')
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showAcceptButton)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CustomButton(
                        text: 'Accept',
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
                        onPressed: onAccept,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CustomButton(
                      text: 'Reject',
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      onPressed: onReject,
                    ),
                  ),
                  CustomButton(
                    text: 'Modify',
                    backgroundColor: Colors.blue,
                    textColor: Colors.white,
                    onPressed: onModify,
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
      case 'modified':
        return isDark ? Colors.amberAccent : Colors.amber;
      default:
        return isDark ? Colors.white70 : Colors.black54;
    }
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}