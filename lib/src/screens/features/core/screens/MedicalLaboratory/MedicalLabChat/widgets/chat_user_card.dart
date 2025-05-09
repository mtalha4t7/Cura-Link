import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cura_link/src/screens/features/authentication/models/chat_user_model.dart';
import 'package:intl/intl.dart';
import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/PatientChat/chat_screen.dart';
import '../../../../../authentication/models/message_type.dart';


class ChatUserCard extends StatelessWidget {
  final ChatUserModelMongoDB user;
  final VoidCallback? onTap;

  const ChatUserCard({
    Key? key,
    required this.user,
    this.onTap,
  }) : super(key: key);

  String _formatMessageTime(String? time) {
    if (time == null || time.isEmpty) return '';

    try {
      DateTime dateTime;

      if (RegExp(r'^\d+$').hasMatch(time)) {
        final timestamp = int.parse(time);
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        dateTime = DateTime.parse(time);
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return DateFormat('h:mm a').format(dateTime);
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE').format(dateTime);
      } else {
        return DateFormat('MMM d').format(dateTime);
      }
    } catch (e) {
      debugPrint('Error formatting time: $e');
      return '';
    }
  }

  ImageProvider? _getProfileImage() {
    if (user.profileImage == null || user.profileImage!.isEmpty) {
      return null;
    }
    try {
      if (user.profileImage!.startsWith("http")) {
        return NetworkImage(user.profileImage!);
      } else {
        Uint8List bytes = base64Decode(user.profileImage!);
        return MemoryImage(bytes);
      }
    } catch (e) {
      debugPrint("Error decoding profile image: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color textSecondaryColor = isDark ? Colors.white70 : Colors.black54;
    final Color primaryColor = const Color(0xFF2979FF);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final currentUserEmail = await UserRepository.instance.getCurrentUser();
          if (currentUserEmail != null && user.userEmail != null) {
            await UserRepository.instance.markMessagesAsRead(
              currentUserEmail,
              user.userEmail!,
            );
          }

          if (onTap != null) {
            onTap!();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(user: user)),
            );
          }
        },
        splashColor: primaryColor.withOpacity(0.1),
        highlightColor: primaryColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildUserAvatar(theme, surfaceColor),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUserInfo(
                    theme, textColor, textSecondaryColor, primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(ThemeData theme, Color surfaceColor) {
    final imageProvider = _getProfileImage();

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.secondary.withOpacity(0.1),
          ),
          child: ClipOval(
            child: imageProvider != null
                ? Image(
              image: imageProvider,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.person,
                  size: 24,
                  color: theme.iconTheme.color?.withOpacity(0.6),
                );
              },
            )
                : Icon(
              Icons.person,
              size: 24,
              color: theme.iconTheme.color?.withOpacity(0.6),
            ),
          ),
        ),
        if (user.userIsOnline == true)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: surfaceColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserInfo(ThemeData theme, Color textColor,
      Color textSecondaryColor, Color primaryColor) {
    final isFromCurrentUser = user.lastMessageFromId == user.userEmail;
    final lastMessagePreview = _getLastMessagePreview(
        user.lastMessage, user.lastMessageType, isFromCurrentUser);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                user.userName ?? 'Unknown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatMessageTime(user.lastMessageTime),
              style: theme.textTheme.bodySmall?.copyWith(
                color: textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                lastMessagePreview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textSecondaryColor,
                  fontSize: 14,
                ),
              ),
            ),
            if (user.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  user.unreadCount > 9 ? '9+' : '${user.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _getLastMessagePreview(
      String? message, MessageType? type, bool isFromCurrentUser) {
    if (message == null) return '';

    switch (type) {
      case MessageType.image:
        return isFromCurrentUser ? '📷 You sent a photo' : '📷 Photo';
      case MessageType.emoji:
        return isFromCurrentUser ? 'You: $message' : message;
      case MessageType.video:
        return isFromCurrentUser ? '🎥 You sent a video' : '🎥 Video';
      case MessageType.file:
        return isFromCurrentUser ? '📄 You sent a file' : '📄 File';
      case MessageType.text:
      default:
        return isFromCurrentUser ? 'You: $message' : message;
    }
  }
}