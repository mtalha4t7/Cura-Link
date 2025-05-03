import 'package:cura_link/src/constants/colors.dart';
import 'package:flutter/material.dart';

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showBadge;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.showBadge = false,
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
            color: isDarkTheme ? tServiceCardDarkBorder : tServiceCardLightBorder,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 40,
                      color: isDarkTheme ? tServiceCardDarkIcon : tServiceCardLightIcon,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDarkTheme ? tWhiteColor : tDarkColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showBadge)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkTheme ? tServiceCardDarkBg : tServiceCardLightBg,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
