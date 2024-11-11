import 'package:cura_link/src/constants/colors.dart';
import 'package:flutter/material.dart';

class AdvanceButton extends StatelessWidget {
  final String imagePath;
  final String title;
  final VoidCallback onTap;

  const AdvanceButton({
    super.key,
    required this.imagePath,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkTheme ? tServiceCardDarkBg : tServiceCardLightBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:isDarkTheme ? tServiceCardLightBorder : tServiceCardDarkBorder,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 80,
              width: 80,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: isDarkTheme ? tWhiteColor : tDarkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
