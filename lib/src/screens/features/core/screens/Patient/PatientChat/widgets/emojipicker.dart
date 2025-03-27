
// Simple emoji picker implementation (you might want to use a package like emoji_picker_flutter instead)
import 'package:flutter/material.dart';

class EmojiPicker extends StatelessWidget {
  final Function(String) onEmojiSelected;
  final Config config;

  const EmojiPicker({
    super.key,
    required this.onEmojiSelected,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    // This is a simplified version - consider using a package for a complete emoji picker
    return Container(
      color: config.bgColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: config.columns,
          childAspectRatio: 1.0,
          crossAxisSpacing: config.horizontalSpacing,
          mainAxisSpacing: config.verticalSpacing,
        ),
        itemCount: _defaultEmojis.length,
        itemBuilder: (context, index) {
          return IconButton(
            icon: Text(
              _defaultEmojis[index],
              style: TextStyle(fontSize: config.emojiSizeMax.toDouble()),
            ),
            onPressed: () => onEmojiSelected(_defaultEmojis[index]),
          );
        },
      ),
    );
  }
}

// Config for emoji picker
class Config {
  final int columns;
  final double emojiSizeMax;
  final double verticalSpacing;
  final double horizontalSpacing;
  final Category initCategory;
  final Color bgColor;
  final Color indicatorColor;
  final Color iconColor;
  final Color iconColorSelected;
  final Color progressIndicatorColor;
  final bool showRecentsTab;
  final int recentsLimit;
  final String noRecentsText;
  final TextStyle noRecentsStyle;
  final CategoryIcons categoryIcons;
  final ButtonMode buttonMode;

  const Config({
    this.columns = 7,
    this.emojiSizeMax = 32,
    this.verticalSpacing = 0,
    this.horizontalSpacing = 0,
    this.initCategory = Category.SMILEYS,
    this.bgColor = const Color(0xFFF2F2F2),
    this.indicatorColor = Colors.blue,
    this.iconColor = Colors.grey,
    this.iconColorSelected = Colors.blue,
    this.progressIndicatorColor = Colors.blue,
    this.showRecentsTab = true,
    this.recentsLimit = 28,
    this.noRecentsText = 'No Recents',
    this.noRecentsStyle = const TextStyle(fontSize: 20, color: Colors.black26),
    this.categoryIcons = const CategoryIcons(),
    this.buttonMode = ButtonMode.MATERIAL,
  });
}

enum Category {
  SMILEYS,
  ANIMALS,
  FOODS,
  TRAVEL,
  ACTIVITIES,
  OBJECTS,
  SYMBOLS,
  FLAGS,
  RECENT
}

class CategoryIcons {
  final IconData smileys;
  final IconData animals;
  final IconData foods;
  final IconData travel;
  final IconData activities;
  final IconData objects;
  final IconData symbols;
  final IconData flags;
  final IconData recent;

  const CategoryIcons({
    this.smileys = Icons.emoji_emotions,
    this.animals = Icons.pets,
    this.foods = Icons.fastfood,
    this.travel = Icons.travel_explore,
    this.activities = Icons.sports_soccer,
    this.objects = Icons.lightbulb,
    this.symbols = Icons.heart_broken,
    this.flags = Icons.flag,
    this.recent = Icons.access_time,
  });
}

enum ButtonMode { MATERIAL, CUPERTINO, IOS }

const List<String> _defaultEmojis = [
  '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣',
  '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰',
  '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜',
  '🤪', '🤨', '🧐', '🤓', '😎', '🤩', '🥳', '😏',
  '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣',
  '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠',
  '😡', '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨',
  '😰', '😥', '😓', '🤗', '🤔', '🤭', '🤫', '🤥',
  '😶', '😐', '😑', '😬', '🙄', '😯', '😦', '😧',
  '😮', '😲', '🥱', '😴', '🤤', '😪', '😵', '🤐',
  '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕', '🤑',
  '🤠', '😈', '👿', '👹', '👺', '🤡', '💩', '👻',
  '💀', '☠️', '👽', '👾', '🤖', '🎃', '😺', '😸',
  '😹', '😻', '😼', '😽', '🙀', '😿', '😾'
];