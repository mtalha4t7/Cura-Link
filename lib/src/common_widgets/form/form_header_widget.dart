import 'package:flutter/material.dart';

class FormHeaderWidget extends StatelessWidget {
  const FormHeaderWidget({
    super.key,
    this.imageColor,
    this.heightBetween,
    required this.image,
    required this.title,
    required this.subTitle,
    this.imageHeight = 0.15,
    this.textAlign,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  // Variables -- Declared in Constructor
  final Color? imageColor;
  final double imageHeight;
  final double? heightBetween;
  final String image, title, subTitle;
  final CrossAxisAlignment crossAxisAlignment;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Check if the theme is dark or light
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        // Use ColorFiltered widget to adjust the image color based on the theme
        Center(
          child: ColorFiltered(
            colorFilter: isDarkTheme
                ? const ColorFilter.mode(
                    Colors.white, // Invert to white for dark mode
                    BlendMode.srcIn,
                  )
                : const ColorFilter.mode(
                    Colors.black, // Invert to black for light mode
                    BlendMode.srcIn,
                  ),
            child: Image.asset(
              image, // Image is passed from the widget's constructor
              height: size.height * imageHeight, // Adjust image height
            ),
          ),
        ),
        SizedBox(height: heightBetween),
        // Title and subtitle
        Text(title, style: Theme.of(context).textTheme.displayMedium),
        Text(
          subTitle,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
