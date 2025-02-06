import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences package

import '../../../../../../shared prefrences/shared_prefrence.dart';
import '../LabBooking/show_lab_services.dart';
import '../LabBooking/temp_userModel.dart';

class UserCard extends StatelessWidget {
  final ShowLabUserModel user;
  final bool isDark;

  const UserCard({
    super.key,
    required this.user,
    required this.isDark,
  });



  @override
  Widget build(BuildContext context) {
    print("Building UserCard for: ${user.fullName}, Email: ${user.email}"); // Debugging statement

    return GestureDetector(
      onTap: () async {
        await saveEmail(user.email);
        await saveLabName(user.fullName);
        // Save email before navigating
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShowLabServices(),
          ),
        );
      },
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                child: Icon(
                  Icons.science, // Use a relevant icon for lab users
                  size: 30,
                  color: isDark ? Colors.white : Colors.grey,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: isDark ? Colors.white : Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
