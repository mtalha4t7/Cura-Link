import 'package:cura_link/src/constants/colors.dart';
import 'package:flutter/material.dart';

class HealthTipCard extends StatelessWidget {
  final String title;

  const HealthTipCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    // Check if the theme is dark or light
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkTheme
            ? const Color.fromARGB(255, 178, 203, 227)
            : tServiceCardLightBg, // Light or dark background color
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.health_and_safety,
            size: 40,
            color: isDarkTheme
                ? Colors.green[300]
                : Colors.green[700],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDarkTheme
                  ? tWhiteColor
                  : tDarkColor, // Adjust text color based on theme
            ),
          ),
        ],
      ),
    );
  }
}
