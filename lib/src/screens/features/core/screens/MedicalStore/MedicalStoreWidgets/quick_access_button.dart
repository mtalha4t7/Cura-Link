import 'package:cura_link/src/constants/colors.dart';
import 'package:flutter/material.dart';

class QuickAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickAccessButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the theme is dark or light
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 30,
            backgroundColor:
                isDarkTheme ? tServiceCardDarkBg : tServiceCardLightBg,
            child: Icon(
              icon,
              size: 30,
              color: isDarkTheme ? tServiceCardDarkIcon : tServiceCardLightIcon,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkTheme ? tWhiteColor : tDarkColor,
          ),
        ),
      ],
    );
  }
}
