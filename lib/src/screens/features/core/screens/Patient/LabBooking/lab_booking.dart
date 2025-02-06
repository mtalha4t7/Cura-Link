import 'package:flutter/material.dart';
import '../PatientControllers/lab_booking_controller.dart';
import '../patientWidgets/lab_users_card.dart';
import 'temp_userModel.dart';

class LabBookingScreen extends StatefulWidget {
  const LabBookingScreen({super.key});

  @override
  _LabBookingScreenState createState() => _LabBookingScreenState();
}

class _LabBookingScreenState extends State<LabBookingScreen> {
  final PatientLabBookingController _controller = PatientLabBookingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Users'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select User",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Users List
            Expanded(
              child: FutureBuilder<List<ShowLabUserModel>>(
                future: _controller.fetchAllUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else if (snapshot.hasData) {
                    final users = snapshot.data!;
                    if (users.isEmpty) {
                      return Center(
                        child: Text(
                          'No Users found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDarkTheme ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        print("User Selected: ${user.fullName}, Email: ${user.email}");
                        return UserCard(user: user, isDark: isDarkTheme);
                      },
                    );
                  } else {
                    return const Center(child: Text('No data found.'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
