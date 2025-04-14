import 'dart:convert';
import 'dart:typed_data';

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

  String _formatMessageSent(String sent) {
    try {
      DateTime dateTime;
      if (sent.contains(RegExp(r'^\d+$'))) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(sent));
      } else {
        dateTime = DateTime.parse(sent);
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (messageDate.isBefore(today)) {
        return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
      } else {
        return DateFormat('h:mm a').format(dateTime);
      }
    } catch (e) {
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
              constraints: BoxConstraints(maxWidth: 250),
              child: _buildMessageContent(isDarkMode),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 5),
          child: Text(
            _formatMessageSent(message.sent),
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
            _formatMessageSent(message.sent),
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
              constraints: BoxConstraints(maxWidth: 250),
              child: _buildMessageContent(isDarkMode),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContent(bool isDarkMode) {
    if (message.type == MessageType.image) {
      try {
        Uint8List imageBytes = base64Decode(message.msg);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            imageBytes,
            width: 200,
            fit: BoxFit.cover,
          ),
        );
      } catch (e) {
        return Text(
          "Invalid image data",
          style: TextStyle(
            fontSize: 14,
            color: Colors.red,
          ),
        );
      }
    } else {
      return Text(
        message.msg,
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? tWhiteColor : tDarkColor,
        ),
      );
    }
  }
}
