import 'dart:convert';
import 'dart:typed_data';
import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:cura_link/src/screens/features/authentication/models/chat_user_model.dart';
import 'package:cura_link/src/screens/features/authentication/models/message_model.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/PatientChat/widgets/chat_input_widget.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/PatientChat/widgets/chat_message_card.dart';
import 'package:flutter/material.dart';
import 'package:cura_link/src/constants/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // For date formatting

class ChatScreen extends StatefulWidget {
  final ChatUserModelMongoDB user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  String? loggedInUserEmail;

  @override
  void initState() {
    super.initState();
    _fetchLoggedInUserEmail();
  }

  /// Fetch currently logged-in user's email
  Future<void> _fetchLoggedInUserEmail() async {
    loggedInUserEmail = await UserRepository.instance.getCurrentUser();
    debugPrint("Logged-in user email: $loggedInUserEmail");
    setState(() {});
  }

  void _sendImage(XFile imageFile) async {
    if (loggedInUserEmail == null) return;

    // You'll need to implement this method in your UserRepository
    await UserRepository.instance.sendImageMessage(
      toId: widget.user.userEmail.toString(),
      fromId: loggedInUserEmail!,
      imageFile: imageFile,
    );

    _scrollToBottom();
  }


  /// Send a message to the database
  void _sendMessage(String messageText) async {
    if (messageText.trim().isEmpty || loggedInUserEmail == null) return;
    final message = Message(
      toId: widget.user.userEmail.toString(),
      fromId: loggedInUserEmail!,
      msg: messageText.trim(),
      read: "false",
      type: MessageType.text,
      sent: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    // Send message to backend/database
    await UserRepository.instance.sendMessageToDatabase(message);

    // Scroll to bottom after sending a message
    _scrollToBottom();
  }

  /// Scroll to the latest message
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.minScrollExtent);
      }
    });
  }

  /// Convert profile image from Base64 if needed
  ImageProvider? _getProfileImage() {
    if (widget.user.profileImage == null || widget.user.profileImage!.isEmpty) {
      return null;
    }

    try {
      if (widget.user.profileImage!.startsWith("http")) {
        return NetworkImage(widget.user.profileImage!);
      } else {
        Uint8List bytes = base64Decode(widget.user.profileImage!);
        return MemoryImage(bytes);
      }
    } catch (e) {
      debugPrint("Error decoding profile image: $e");
      return null;
    }
  }

  /// Format the last active timestamp into a user-friendly string
  String _formatLastActive(String? lastActive) {
    if (lastActive == null || lastActive.isEmpty) {
      return "Last seen not available";
    }

    try {
      // Parse the lastActive value into a DateTime object
      DateTime dateTime;
      if (lastActive.contains(RegExp(r'^\d+$'))) {
        // If lastActive is a timestamp (e.g., "1672531200000")
        dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(lastActive));
      } else {
        // If lastActive is an ISO string (e.g., "2023-01-01T12:00:00Z")
        dateTime = DateTime.parse(lastActive);
      }

      // Format the DateTime object
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (messageDate.isAtSameMomentAs(today)) {
        // If the user was active today, show only the time
        return "Last seen today at ${DateFormat('h:mm a').format(dateTime)}";
      } else if (messageDate.isAfter(today.subtract(const Duration(days: 1)))) {
        // If the user was active yesterday, show "Yesterday"
        return "Last seen yesterday at ${DateFormat('h:mm a').format(dateTime)}";
      } else {
        // Otherwise, show the full date and time
        return "Last seen on ${DateFormat('MMM d, yyyy h:mm a').format(dateTime)}";
      }
    } catch (e) {
      debugPrint("Error formatting last active: $e");
      return "Last seen not available";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 1.0,
          automaticallyImplyLeading: false,
          backgroundColor: isDarkMode ? tDarkColor : tPrimaryColor,
          title: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back,
                  color: isDarkMode ? tWhiteColor : Colors.black54,
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.grey[300],
                backgroundImage: _getProfileImage(),
                child: _getProfileImage() == null
                    ? Icon(Icons.person, color: tWhiteColor)
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.userName ?? "Unknown User",
                    style: TextStyle(
                      color: isDarkMode ? tWhiteColor : tDarkColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatLastActive(widget.user.userLastActive), // Use formatted date
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: UserRepository.instance.getAllMessagesStream(widget.user.userEmail.toString()).map(
                      (snapshot) {
                    debugPrint("Fetched raw messages: $snapshot");
                    return snapshot
                        .map((json) => Message.fromJson(json))
                        .toList();
                  },
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    debugPrint("No messages found.");
                    return const Center(child: Text("No messages yet."));
                  }

                  List<Message> messages = snapshot.data!;

                  // Sorting messages by timestamp (newest first)
                  messages.sort((a, b) {
                    try {
                      DateTime aTime = DateTime.tryParse(a.sent) ??
                          DateTime.fromMillisecondsSinceEpoch(int.parse(a.sent));
                      DateTime bTime = DateTime.tryParse(b.sent) ??
                          DateTime.fromMillisecondsSinceEpoch(int.parse(b.sent));
                      return bTime.compareTo(aTime); // Descending order
                    } catch (e) {
                      debugPrint("Sorting error: $e");
                      return 0;
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    reverse: true, // Auto-scroll to latest message
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      debugPrint("Rendering message: ${message.toJson()}");

                      return ChatMessageCard(
                        message: message,
                        isFromCurrentUser: message.fromId == loggedInUserEmail,
                      );
                    },
                  );
                },
              ),
            ),
            ChatInput(onSendMessage: _sendMessage)
          ],
        ),
      ),
    );
  }
}