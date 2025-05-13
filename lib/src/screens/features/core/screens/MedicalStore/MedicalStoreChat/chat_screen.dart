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
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

import '../../../../authentication/models/message_type.dart';


class ChatScreen extends StatefulWidget {
  final ChatUserModelMongoDB user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  String? loggedInUserEmail;
  bool _isLoading = true;
  final List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchLoggedInUserEmail();
  }

  Future<void> _fetchLoggedInUserEmail() async {
    loggedInUserEmail = await UserRepository.instance.getCurrentUser();
    setState(() => _isLoading = false);
  }

  void _sendMessage(String messageText) async {
    if (messageText.trim().isEmpty || loggedInUserEmail == null) return;

    final message = Message(
      toId: widget.user.userEmail.toString(),
      fromId: loggedInUserEmail!,
      msg: messageText.trim(),
      read: "false",
      type: _isEmojiOnly(messageText.trim())
          ? MessageType.emoji
          : MessageType.text,
      sent: DateTime.now().toUtc().add(Duration(hours:5)).toIso8601String(),
    );

    await UserRepository.instance.sendMessageToDatabase(message);
    _scrollToBottom();
  }

  void _sendImage(XFile imageFile) async {
    if (loggedInUserEmail == null) return;

    await UserRepository.instance.sendImageMessage(
      toId: widget.user.userEmail.toString(),
      fromId: loggedInUserEmail!,
      imageFile: imageFile,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  bool _isEmojiOnly(String text) {
    final emojiRegex = RegExp(
      r'^(\p{Emoji_Presentation}|\p{Emoji}\uFE0F)+$',
      unicode: true,
    );
    return emojiRegex.hasMatch(text);
  }

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

  String _formatLastActive(String? lastActive) {
    if (lastActive == null || lastActive.isEmpty) return "Last seen not available";

    try {
      DateTime dateTime;
      if (lastActive.contains(RegExp(r'^\d+$'))) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(lastActive));
      } else {
        dateTime = DateTime.parse(lastActive);
      }

      final now =  DateTime.now().toUtc().add(Duration(hours:5));
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (messageDate.isAtSameMomentAs(today)) {
        return "Last seen today at ${DateFormat('h:mm a').format(dateTime)}";
      } else if (messageDate.isAfter(today.subtract(const Duration(days: 1)))) {
        return "Last seen yesterday at ${DateFormat('h:mm a').format(dateTime)}";
      } else {
        return "Last seen on ${DateFormat('MMM d, yyyy h:mm a').format(dateTime)}";
      }
    } catch (e) {
      return "Last seen not available";
    }
  }

  List<Message> _sortMessages(List<Message> messages) {
    try {
      messages.sort((a, b) {
        final aTime = DateTime.parse(a.sent);
        final bTime = DateTime.parse(b.sent);
        return aTime.compareTo(bTime);
      });
    } catch (e) {
      debugPrint("Error sorting messages: $e");
    }
    return messages;
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: PhotoView(
              imageProvider: imageUrl.startsWith('http')
                  ? NetworkImage(imageUrl)
                  : MemoryImage(base64Decode(imageUrl)) as ImageProvider,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final profileImage = _getProfileImage();

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
                backgroundImage: profileImage,
                child: profileImage == null
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
                    _formatLastActive(widget.user.userLastActive),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: UserRepository.instance
                    .getAllMessagesStream(widget.user.userEmail.toString())
                    .map((snapshot) {
                  return _sortMessages(snapshot.map(Message.fromJson).toList());
                }),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No messages yet"));
                  }

                  final messages = snapshot.data!;
                  _messages.clear();
                  _messages.addAll(messages);

                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return ChatMessageCard(
                        message: message,
                        isFromCurrentUser: message.fromId == loggedInUserEmail,
                        onImageTap: () {
                          if (message.type == MessageType.image) {
                            _showFullScreenImage(message.msg);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
            ChatInput(
              onSendMessage: _sendMessage,
              onSendImage: _sendImage,
            ),
          ],
        ),
      ),
    );
  }
}