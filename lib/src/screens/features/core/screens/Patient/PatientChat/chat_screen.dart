import 'dart:typed_data';

import 'package:cura_link/src/screens/features/authentication/models/chat_user_model.dart';
import 'package:flutter/material.dart';
import 'package:cura_link/src/constants/colors.dart'; // Import your colors

class ChatScreen extends StatefulWidget {
  final ChatUserModelMongoDB user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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
            title: InkWell(
              onTap: () {},
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context); // Navigate back on button press
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDarkMode ? tWhiteColor : Colors.black54,
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    backgroundImage: widget.user.profileImage != null
                        ? MemoryImage(widget.user.profileImage! as Uint8List)
                        : null,
                    child: widget.user.profileImage == null
                        ? Icon(Icons.person, color: tWhiteColor)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                        widget.user.userLastActive ?? "Last seen not availabe",
                        style: TextStyle(color: Colors.black12, fontSize: 13),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: Column(
            children: [_chatInput()],
          )),
    );
  }

  Widget _chatInput() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.01,
        horizontal: MediaQuery.of(context).size.width * 0.025,
      ),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // Navigate back on button press
                    },
                    icon: Icon(
                      Icons.emoji_emotions,
                      color: isDarkMode ? tAccentColor : tAccentColor,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Type Something...',
                        hintStyle: TextStyle(
                            color: Colors.blueAccent), // Fixed color reference
                        border: InputBorder.none, // Removed default border
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Navigate back on button press
                    },
                    icon: Icon(
                      Icons.image,
                      color: isDarkMode ? tPrimaryColor : tPrimaryColor,
                      size: 25,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Navigate back on button press
                    },
                    icon: Icon(
                      Icons.camera_alt_rounded,
                      color: isDarkMode ? tPrimaryColor : tPrimaryColor,
                      size: 25,
                    ),
                  ),
                ],
              ),
            ),
          ),
          MaterialButton(
            padding: EdgeInsets.only(right: 5, top: 10, bottom: 10, left: 10),
            onPressed: () {},
            shape: const CircleBorder(),
            color: Colors.green,
            child: Icon(
              Icons.send,
              color: isDarkMode ? tCardBgColor : tDarkColor,
              size: 25,
            ),
          )
        ],
      ),
    );
  }
}
