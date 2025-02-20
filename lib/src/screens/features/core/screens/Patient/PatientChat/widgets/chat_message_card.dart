import 'package:cura_link/src/constants/colors.dart';
import 'package:cura_link/src/screens/features/authentication/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatMessageCard extends StatelessWidget {
  final Message message;
  final bool isFromCurrentUser;

  const ChatMessageCard({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
  });

  /// Format timestamp for message
  // String _formatSentTime(String sent) {
  //   try {
  //     // Attempt to parse directly (if in ISO 8601 format)
  //     DateTime dateTime = DateTime.parse(sent);
  //     return DateFormat('hh:mm a | dd MMM').format(dateTime);
  //   } catch (e) {
  //     try {
  //       // Handle alternative formats (e.g., if milliseconds since epoch)
  //       int timestamp = int.parse(sent);
  //       DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
  //       return DateFormat('hh:mm a | dd MMM').format(dateTime);
  //     } catch (e) {
  //       return "Invalid date"; // Handle invalid cases gracefully
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // ✅ Get context inside build method
    final isDarkMode = theme.brightness == Brightness.dark;

    return isFromCurrentUser
        ? _greenMessage(isDarkMode)
        : _blueMessage(isDarkMode);
  }

  Widget _blueMessage(bool isDarkMode) {
    return Align(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.msg,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? tWhiteColor : tDarkColor,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "12:00",
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _greenMessage(bool isDarkMode) {
    return Align(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.msg,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? tDarkColor : tWhiteColor,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                " 12:00",
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
