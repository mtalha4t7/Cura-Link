import 'dart:convert';
import 'package:cura_link/src/screens/features/authentication/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:cura_link/src/constants/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../authentication/models/message_type.dart';

class ChatMessageCard extends StatelessWidget {
  final Message message;
  final bool isFromCurrentUser;
  final VoidCallback? onImageTap;

  const ChatMessageCard({
    Key? key,
    required this.message,
    required this.isFromCurrentUser,
    this.onImageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: isFromCurrentUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: isFromCurrentUser
              ? isDark
              ? tPrimaryColor
              : tPrimaryColor.withOpacity(0.8)
              : isDark
              ? tDarkColor
              : Colors.grey[200],
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _buildMessageContent(theme, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(ThemeData theme, bool isDark) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageMessage(theme);
      case MessageType.emoji:
        return _buildEmojiMessage();
      default:
        return _buildTextMessage(theme, isDark);
    }
  }

  Widget _buildTextMessage(ThemeData theme, bool isDark) {
    return Text(
      message.msg,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isFromCurrentUser ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildEmojiMessage() {
    return Text(
      message.msg,
      style: const TextStyle(fontSize: 32),
    );
  }

  Widget _buildImageMessage(ThemeData theme) {
    final isNetworkImage = message.msg.startsWith('http');

    return GestureDetector(
      onTap: onImageTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isNetworkImage
            ? CachedNetworkImage(
          imageUrl: message.msg,
          placeholder: (context, url) => Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          ),
          fit: BoxFit.cover,
          width: 200,
          height: 200,
        )
            : Image.memory(
          base64Decode(message.msg),
          fit: BoxFit.cover,
          width: 200,
          height: 200,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            );
          },
        ),
      ),
    );
  }
}