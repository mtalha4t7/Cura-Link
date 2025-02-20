import 'dart:convert';
import 'dart:typed_data';
import 'package:cura_link/src/screens/features/core/screens/Patient/PatientChat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:cura_link/src/screens/features/authentication/models/chat_user_model.dart';
import 'package:cura_link/src/constants/colors.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUserModelMongoDB user;

  const ChatUserCard({super.key, required this.user});

  @override
  _ChatUserCardState createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  Uint8List? profileImageBytes;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  /// Loads and decodes the Base64 profile image
  void _loadProfileImage() {
    if (widget.user.profileImage != null &&
        widget.user.profileImage!.isNotEmpty) {
      try {
        profileImageBytes = base64Decode(widget.user.profileImage!);
        setState(() {}); // Update UI after decoding
      } catch (e) {
        print("Error decoding profile image: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: isDarkMode
          ? const Color.fromARGB(255, 31, 38, 41)
          : tServiceCardLightBg, // Background based on mode
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  user: widget.user,
                ),
              ));
        },
        child: ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[300],
            backgroundImage: profileImageBytes != null
                ? MemoryImage(profileImageBytes!) // Load from memory
                : null,
            child: profileImageBytes == null
                ? Icon(Icons.person,
                    color: tWhiteColor, size: 30) // Default icon
                : null,
          ),
          title: Text(
            widget.user.userName ?? 'Unknown User',
            style: theme.textTheme.titleMedium?.copyWith(
              color:
                  isDarkMode ? tWhiteColor : tDarkColor, // Adaptive text color
            ),
          ),
          subtitle: Text(
            widget.user.userAbout ?? 'No status available',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDarkMode
                  ? Colors.grey[400]
                  : tDarkColor.withOpacity(0.7), // Subtitle color
            ),
          ),
          trailing: Text(
            "03:00 AM",
            style: TextStyle(
              color: isDarkMode
                  ? Colors.grey[400]
                  : Colors.grey.shade600, // Time color based on mode
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
