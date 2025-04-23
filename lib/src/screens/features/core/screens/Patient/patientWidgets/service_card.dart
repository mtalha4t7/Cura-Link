import 'package:cura_link/src/constants/colors.dart';
import 'package:flutter/material.dart';

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showBadge; // <-- new param

  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.showBadge = false, // default false
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDarkTheme ? tServiceCardDarkBg : tServiceCardLightBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkTheme ? tServiceCardDarkBorder : tServiceCardLightBorder,
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
          if (showBadge)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
