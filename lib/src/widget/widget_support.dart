import 'package:flutter/material.dart';

class AppColors {
    static const Color primaryColor = Color(0xFF00838F); // Teal/Blue-Green
    static const Color secondaryColor = Color(0xFF26C6DA); // Lighter Teal
    static const Color accentColor = Color(0xFFFF7043); // Accent (Orange)
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Background
  static const Color textColor = Colors.black;
  static const Color lightTextColor = Colors.black54;
  static const Color buttonTextColor = Colors.white;
  static const Color errorColor = Colors.redAccent; // For validation or errors
}

class AppWidget {
  static TextStyle boldTextFieldStyle() {
    return const TextStyle(
      color: AppColors.textColor,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'Poppins',
    );
  }

  static TextStyle headlineTextFieldStyle() {
    return const TextStyle(
      color: AppColors.textColor,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      fontFamily: 'Poppins',
    );
  }

  static TextStyle lightTextFieldStyle() {
    return const TextStyle(
      color: AppColors.lightTextColor,
      fontSize: 15.0,
      fontWeight: FontWeight.w500,
      fontFamily: 'Poppins',
    );
  }

  static TextStyle semiBoldTextFieldStyle() {
    return const TextStyle(
      color: AppColors.textColor,
      fontSize: 18.0,
      fontWeight: FontWeight.w500,
      fontFamily: 'Poppins',
    );
  }

  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      foregroundColor: AppColors.buttonTextColor, backgroundColor: AppColors.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      textStyle: const TextStyle(
        fontSize: 18,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.bold,
      ),
    );
  }
}


class RoleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const RoleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    double size = MediaQuery.of(context).size.width * 0.4; // Set size based on screen width

    return SizedBox(
      width: size,
      height: size, // Make the button circular
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color, // Button background color
          shape: const CircleBorder(), // Circular shape
          padding: const EdgeInsets.all(20), // Adjust padding for inner spacing
          elevation: 8, // Elevation for 3D effect
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: AppColors.buttonTextColor, // Use button text color from AppColors
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.buttonTextColor), // Use button text color from AppColors
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

