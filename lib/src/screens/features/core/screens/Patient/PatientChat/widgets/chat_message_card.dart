import 'package:cura_link/src/constants/colors.dart';
import 'package:cura_link/src/screens/features/authentication/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class ChatMessageCard extends StatelessWidget {
  final Message message;
  final bool isFromCurrentUser;

  const ChatMessageCard({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment:
      isFromCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        isFromCurrentUser
            ? _greenMessage(isDarkMode)
            : _blueMessage(isDarkMode),
      ],
    );
  }

  // Helper function to format the message.sent timestamp
  String _formatMessageSent(String sent) {
    try {
      // Parse the sent value into a DateTime object
      DateTime dateTime;
      if (sent.contains(RegExp(r'^\d+$'))) {
        // If sent is a timestamp (e.g., "1672531200000")
        dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(sent));
      } else {
        // If sent is an ISO string (e.g., "2023-01-01T12:00:00Z")
        dateTime = DateTime.parse(sent);
      }

      // Format the DateTime object
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (messageDate.isBefore(today)) {
        // Show date and time for older messages
        return DateFormat('MMM d, yyyy h:mm a').format(dateTime); // Example: "Jan 1, 2023 12:00 PM"
      } else {
        // Show only time for today's messages
        return DateFormat('h:mm a').format(dateTime); // Example: "12:00 PM"
      }
    } catch (e) {
      // Fallback in case of parsing errors
      return sent;
    }
  }

  Widget _blueMessage(bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isDarkMode ? tDarkColor : tPrimaryColor.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              constraints: BoxConstraints(
                maxWidth: 250, // Adjusts width dynamically
              ),
              child: Text(
                message.msg,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? tWhiteColor : tDarkColor,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 5),
          child: Text(
            _formatMessageSent(message.sent), // Use formatted date
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.blue : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _greenMessage(bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 5),
          child: Text(
            _formatMessageSent(message.sent), // Use formatted date
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.blue : Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isDarkMode ? tAccentColor : Colors.green[300],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              constraints: BoxConstraints(
                maxWidth: 250, // Adjusts width dynamically
              ),
              child: Text(
                message.msg,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? tDarkColor : tWhiteColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}