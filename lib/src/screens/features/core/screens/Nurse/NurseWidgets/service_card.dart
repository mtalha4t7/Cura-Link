import 'package:cura_link/src/constants/colors.dart';
import 'package:flutter/material.dart';

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the theme is dark or light
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkTheme ? tServiceCardDarkBg : tServiceCardLightBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isDarkTheme ? tServiceCardDarkBorder : tServiceCardLightBorder,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isDarkTheme ? tServiceCardDarkIcon : tServiceCardLightIcon,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDarkTheme ? tWhiteColor : tDarkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
