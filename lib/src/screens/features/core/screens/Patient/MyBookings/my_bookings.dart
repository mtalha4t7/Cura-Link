import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabWidgets/booking_card.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/patient_bookings_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../PatientControllers/my_bookings_controller.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  _MyBookingsScreenState createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final MyBookingsController _controller = MyBookingsController();

  // Function to format date
  String formatDate(String rawDate) {
    try {
      final parsedDate = DateTime.parse(rawDate);
      return DateFormat.yMMMMEEEEd().add_jm().format(parsedDate);
    } catch (e) {
      return rawDate; // Fallback to raw date if parsing fails
    }
  }

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
                        final price = booking['price']?.toString() ?? '0.0';
                        return PatientBookingsCard(
                          LabUserName: booking['labUserName'],
                          testName: booking['testName'],
                          bookingDate: formatDate(booking['bookingDate']),
                          status: booking['status'] ?? 'Pending',
                          price: price, // Explicitly specify the price parameter
                          isDark: isDarkTheme,
                          onAccept: () {
                            if(booking['status']=="Modified"){
                              _controller.updateBookingStatus(
                                booking['bookingId'], // MongoDB ObjectId
                                'Accepted',
                              );
                              setState(() {});
                            }else{
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('You can only Accept,When booking is modified by Lab'),
                                  duration: const Duration(seconds: 3), // Duration of SnackBar
                                ),
                              );
                            }
                          },
                          onReject: () {
                            if(booking['status']!="Accepted"){

                              _controller.rejectAndDeleteBooking(booking['bookingId']);
                              setState(() {});
                            }else{
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Once Accepted, you cannot cancel the booking'),
                                  duration: const Duration(seconds: 3), // Duration of SnackBar
                                ),
                              );

                            }

                          },
                          onModify: () {
                            if(booking['status']!="Accepted"){
                              _showModifyDialog(context, booking);
                            }
                            else{
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Booking is accepted, you cannot Modify This Booking'),
                                  duration: const Duration(seconds: 3), // Duration of SnackBar
                                ),
                              );
                            }

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

  void _showModifyDialog(BuildContext context, Map<String, dynamic> booking) async {
    final TextEditingController modifyDateController =
    TextEditingController(text: booking['bookingDate']);
    DateTime selectedDate = DateTime.parse(booking['bookingDate']);

    // Show the date picker
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (newDate != null) {
      // Show the time picker
      TimeOfDay? newTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate),
      );

      if (newTime != null) {
        // Combine the selected date and time
        final DateTime combinedDateTime = DateTime(
          newDate.year,
          newDate.month,
          newDate.day,
          newTime.hour,
          newTime.minute,
        );

        // Format the combined DateTime
        String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);

        // Update the TextField
        modifyDateController.text = formattedDate;

        // Confirm the changes and save
        _controller.updateBookingDate(
          booking['_id'], // MongoDB ObjectId
          formattedDate,
        );
        setState(() {}); // Refresh the UI after update
        Navigator.pop(context); // Close the dialog
      }
    }
  }
}
