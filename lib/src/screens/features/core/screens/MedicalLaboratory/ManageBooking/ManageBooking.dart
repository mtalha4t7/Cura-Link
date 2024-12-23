import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabWidgets/booking_card.dart';
import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabWidgets/custom_button.dart';
import 'package:flutter/material.dart';

import '../MedicalLabControllers/lab_manage_booking_controller.dart';

class ManageBookingScreen extends StatefulWidget {
  const ManageBookingScreen({super.key});

  @override
  _ManageBookingScreenState createState() => _ManageBookingScreenState();
}

class _ManageBookingScreenState extends State<ManageBookingScreen> {
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _testNameController = TextEditingController();
  final TextEditingController _bookingDateController = TextEditingController();
  final BookingController _controller = BookingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookings'),
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
              "Manage Bookings",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Patient Name Field
            _buildTextField(
              controller: _patientNameController,
              label: 'Enter Patient Name',
              hint: 'E.g., John Doe',
              icon: Icons.person,
              isDark: isDarkTheme,
            ),
            const SizedBox(height: 16),

            // Test Name Field
            _buildTextField(
              controller: _testNameController,
              label: 'Enter Test Name',
              hint: 'E.g., Blood Test',
              icon: Icons.medical_services,
              isDark: isDarkTheme,
            ),
            const SizedBox(height: 16),

            // Booking Date Field
            _buildTextField(
              controller: _bookingDateController,
              label: 'Enter Booking Date',
              hint: 'E.g., 2024-12-25',
              icon: Icons.calendar_today,
              isDark: isDarkTheme,
            ),
            const SizedBox(height: 16),

            // Add Booking Button
            CustomButton(
              text: 'Add Booking',
              isDark: isDarkTheme,
              onPressed: () {
                final patientName = _patientNameController.text.trim();
                final testName = _testNameController.text.trim();
                final bookingDate = _bookingDateController.text.trim();
                if (patientName.isNotEmpty &&
                    testName.isNotEmpty &&
                    bookingDate.isNotEmpty) {
                  _controller
                      .addBooking(patientName, testName, bookingDate)
                      .then((_) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Booking added successfully!')),
                    );
                  }).catchError((error) {
                    _showErrorSnackbar(context, 'Error adding booking: $error');
                  });
                  _patientNameController.clear();
                  _testNameController.clear();
                  _bookingDateController.clear();
                } else {
                  _showErrorSnackbar(context, 'Please fill in all fields.');
                }
              },
            ),
            const SizedBox(height: 16),

            // Bookings List
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _controller.fetchUserBookings(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else if (snapshot.hasData) {
                    final bookings = snapshot.data!;
                    if (bookings.isEmpty) {
                      return Center(
                        child: Text(
                          'No bookings found.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                isDarkTheme ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return BookingCard(
                          patientName: booking['patientName'],
                          testName: booking['testName'],
                          bookingDate: booking['bookingDate'],
                          status: booking['status'] ?? 'Pending',
                          isDark: isDarkTheme,
                          onAccept: () {
                            _controller.updateBookingStatus(
                              booking['id'],
                              'Accepted',
                            );
                            setState(() {});
                          },
                          onReject: () {
                            _controller.updateBookingStatus(
                              booking['id'],
                              'Rejected',
                            );
                            setState(() {});
                          },
                          onModify: () {
                            _showModifyDialog(context, booking);
                          },
                        );
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey[200],
        labelStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showModifyDialog(BuildContext context, Map<String, dynamic> booking) {
    final TextEditingController modifyDateController =
        TextEditingController(text: booking['bookingDate']);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modify Booking Date'),
          content: _buildTextField(
            controller: modifyDateController,
            label: 'New Booking Date',
            hint: 'E.g., 2024-12-30',
            icon: Icons.calendar_today,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _controller.updateBookingDate(
                  booking['id'],
                  modifyDateController.text.trim(),
                );
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
