import 'package:flutter/material.dart';
import 'package:cura_link/src/constants/colors.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage; // Callback to send message

  const ChatInput({super.key, required this.onSendMessage});

  @override
  _ChatInputState createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSendMessage(_controller.text.trim());
      _controller.clear(); // Clear input field after sending
    }
  }

  @override
  Widget build(BuildContext context) {
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
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {}, // Handle emoji button action
                    icon: Icon(
                      Icons.emoji_emotions,
                      color: tAccentColor,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type something...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.blueAccent : Colors.black,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {}, // Handle image selection
                    icon: Icon(
                      Icons.image,
                      color: tPrimaryColor,
                      size: 25,
                    ),
                  ),
                  IconButton(
                    onPressed: () {}, // Handle camera button action
                    icon: Icon(
                      Icons.camera_alt_rounded,
                      color: tPrimaryColor,
                      size: 25,
                    ),
                  ),
                ],
              ),
            ),
          ),
          MaterialButton(
            padding: const EdgeInsets.all(10),
            onPressed: _sendMessage,
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
