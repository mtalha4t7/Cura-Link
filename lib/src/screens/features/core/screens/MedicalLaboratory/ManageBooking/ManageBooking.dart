import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabWidgets/booking_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../MedicalLabControllers/lab_manage_booking_controller.dart';

class ManageBookingScreen extends StatefulWidget {
  const ManageBookingScreen({super.key});

  @override
  _ManageBookingScreenState createState() => _ManageBookingScreenState();
}
class _ManageBookingScreenState extends State<ManageBookingScreen> {
  final BookingController _controller = BookingController();

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
                            color: isDarkTheme ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        final price = booking['price']?.toString() ?? '0.0'; // Ensure price is String

                        return BookingCard(
                          patientName: booking['patientName'] ?? 'Unknown',
                          testName: booking['testName'] ?? 'Unknown Test',
                          bookingDate: formatDate(booking['bookingDate'] ?? ''),
                          status: booking['status'] ?? 'Pending',
                          price: price,
                          isDark: isDarkTheme,
                          onAccept: () {
                            if(booking['status']!="Modified"){
                              _controller.updateBookingStatus(
                                booking['_id'].toHexString(), // Convert ObjectId to String
                                'Accepted',
                              );
                              setState(() {});
                            }else{
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Once modified, patient can accept this booking.'),
                                    duration: const Duration(seconds: 3), // Duration of SnackBar
                                  ),
                              );
                            }
                          },
                          onReject: () {
                            if(booking['status']!="Accepted"){
                              _controller.rejectAndDeleteBooking(
                                  booking['_id'].toHexString()
                              );
                              setState(() {});
                            }else{
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Booking is already accepted!'),
                                  duration: const Duration(seconds: 3), // Duration of SnackBar
                                ),
                              );
                            }

                          },
                          onModify: () {
                            if(booking['status']!="Accepted"){
                              _showModifyDialog(context, booking);
                            }else{
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('You cannot modify accepted Booking!'),
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

        // Update the booking date and set status to "Modified"
        await _controller.updateBookingDate(
          booking['_id'].toHexString(), // Convert ObjectId to String
          formattedDate,
        );
        await _controller.updateBookingStatus(
          booking['_id'].toHexString(), // Convert ObjectId to String
          'Modified', // Change status to "Modified"
        );

        setState(() {}); // Refresh the UI after update
        Navigator.pop(context); // Close the dialog
      }
    }
  }
}
