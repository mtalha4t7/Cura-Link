import 'package:flutter/material.dart';
import '../LabBooking/complete_booking_button_widget.dart';
import '../MyBookings/MyBooking_widgets/RatingButton.dart';

class MessageButton extends StatelessWidget {
  final VoidCallback onPressed;

  const MessageButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black26,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
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

class PatientBookingsCard extends StatelessWidget {
  final String labUserName;
  final String testName;
  final String bookingDate;
  final String status;
  final String price;
  final bool isDark;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onModify;
  final VoidCallback onMessage;
  final VoidCallback? onRate;
  final VoidCallback? onComplete;
  final bool hasRating;
  final bool showAcceptButton;
  final String bookingId;

  const PatientBookingsCard({
    super.key,
    required this.labUserName,
    required this.testName,
    required this.bookingDate,
    required this.status,
    required this.price,
    required this.isDark,
    required this.onAccept,
    required this.onReject,
    required this.onModify,
    required this.onMessage,
    this.onRate,
    this.onComplete,
    required this.hasRating,
    required this.showAcceptButton,
    required this.bookingId,
  });

  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isCompleted => status.toLowerCase() == 'completed';

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
              'Lab: $labUserName',
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
              'Price: \Rs$price',
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
            MessageButton(onPressed: onMessage),
            const SizedBox(height: 12),
            if (isAccepted && !isCompleted)
              CompleteBookingButton(
                onPressed: onComplete,
              ),
            if (isCompleted && !isAccepted) const SizedBox(height: 12),
            if (isCompleted)
              RateButton(
                enabled: !hasRating && onRate != null,
                onPressed: hasRating ? null : onRate,
              ),
            if (isAccepted) const SizedBox(height: 12),
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
      case 'completed':
        return Colors.purple;
      default:
        return isDark ? Colors.white70 : Colors.black54;
    }
  }
}