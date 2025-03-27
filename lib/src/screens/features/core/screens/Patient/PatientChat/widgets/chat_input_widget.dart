import 'package:cura_link/src/screens/features/core/screens/Patient/PatientChat/widgets/emojipicker.dart';
import 'package:flutter/material.dart';
import 'package:cura_link/src/constants/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(XFile)? onSendImage;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.onSendImage,
  });

  @override
  _ChatInputState createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _showEmojiPicker = false;

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSendMessage(_controller.text.trim());
      _controller.clear();
      setState(() => _showEmojiPicker = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null && widget.onSendImage != null) {
        widget.onSendImage!(image);
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to pick image: $e');
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      // Close keyboard when emoji picker is shown
      if (_showEmojiPicker) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  void _onEmojiSelected(String emoji) {
    _controller.text = _controller.text + emoji;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      children: [
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: _onEmojiSelected,
              config: Config(
                columns: 7,
                emojiSizeMax: 32,
                verticalSpacing: 0,
                horizontalSpacing: 0,
                initCategory: Category.RECENT,
                bgColor: isDarkMode ? tDarkColor : tWhiteColor,
                indicatorColor: tPrimaryColor,
                iconColor: Colors.grey,
                iconColorSelected: tPrimaryColor,
                progressIndicatorColor: tPrimaryColor,
                showRecentsTab: true,
                recentsLimit: 28,
                noRecentsText: 'No Recents',
                noRecentsStyle: TextStyle(
                  fontSize: 20,
                  color: isDarkMode ? tWhiteColor : tDarkColor,
                ),
                categoryIcons: const CategoryIcons(),
                buttonMode: ButtonMode.MATERIAL,
              ),
            ),
          ),
        Padding(
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
                        onPressed: _toggleEmojiPicker,
                        icon: Icon(
                          Icons.emoji_emotions,
                          color: _showEmojiPicker ? tPrimaryColor : tAccentColor,
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
                          onTap: () {
                            if (_showEmojiPicker) {
                              setState(() => _showEmojiPicker = false);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: Icon(
                          Icons.image,
                          color: tPrimaryColor,
                          size: 25,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _pickImage(ImageSource.camera),
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
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
