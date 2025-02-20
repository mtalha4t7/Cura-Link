import 'package:cura_link/src/constants/colors.dart';
import 'package:flutter/material.dart';

class chatInput extends StatelessWidget {
  const chatInput({super.key});

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
                    onPressed: () {},
                    icon: Icon(
                      Icons.emoji_emotions,
                      color: isDarkMode ? tAccentColor : tAccentColor,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      style: TextStyle(
                        fontSize: 16, // Ensure consistent text size
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type something...',
                        hintStyle: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 12, // Explicitly setting hint text size
                          color: isDarkMode ? Colors.blueAccent : Colors.black,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.image,
                      color: isDarkMode ? tPrimaryColor : tPrimaryColor,
                      size: 25,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
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
            padding: const EdgeInsets.all(10),
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
