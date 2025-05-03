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

  String formatDate(String rawDate) {
    try {
      final parsedDate = DateTime.parse(rawDate);
      return DateFormat.yMMMMEEEEd().add_jm().format(parsedDate);
    } catch (e) {
      return rawDate;
    }
  }

  Future<bool> _showConfirmationDialog(
      BuildContext context, String title, String message, IconData icon) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Confirmation",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: AlertDialog(
            backgroundColor:
            isDark ? Colors.grey[900] : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: Text(
              message,
              style: theme.textTheme.bodyMedium,
            ),
            actionsPadding: const EdgeInsets.only(
                bottom: 12, right: 12, left: 12),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.secondary,
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.check),
                label: const Text('Confirm'),
              ),
            ],
          ),
        );
      },
    ) ??
        false;
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
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _controller.fetchUserBookings(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData) {
                    final bookings = snapshot.data!;
                    if (bookings.isEmpty) {
                      return Center(
                        child: Text(
                          'No bookings found.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDarkTheme
                                ? Colors.white54
                                : Colors.black54,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        final price =
                            booking['price']?.toString() ?? '0.0';

                        return BookingCard(
                          patientName: booking['patientName'] ?? 'Unknown',
                          testName: booking['testName'] ?? 'Unknown Test',
                          bookingDate: formatDate(
                              booking['bookingDate'] ?? ''),
                          status: booking['status'] ?? 'Pending',
                          price: price,
                          isDark: isDarkTheme,
                          onAccept: () async {
                            final confirm = await _showConfirmationDialog(
                              context,
                              'Accept Booking',
                              'Are you sure you want to accept this booking?',
                              Icons.check_circle_outline,
                            );
                            if (!confirm) return;

                            if (booking['status'] != "Modified") {
                              await _controller.updateBookingStatus(
                                booking['_id'].toHexString(),
                                'Accepted',
                              );
                              setState(() {});
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Once modified, patient can accept this booking.'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          onReject: () async {
                            final confirm = await _showConfirmationDialog(
                              context,
                              'Reject Booking',
                              'Are you sure you want to reject this booking?',
                              Icons.cancel_outlined,
                            );
                            if (!confirm) return;

                            if (booking['status'] != "Accepted") {
                              await _controller.rejectAndDeleteBooking(
                                booking['_id'].toHexString(),
                              );
                              setState(() {});
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Booking is already accepted!'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          onModify: () async {
                            final confirm = await _showConfirmationDialog(
                              context,
                              'Modify Booking',
                              'Do you want to modify the date/time for this booking?',
                              Icons.edit_calendar_outlined,
                            );
                            if (!confirm) return;

                            if (booking['status'] != "Accepted") {
                              _showModifyDialog(context, booking);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'You cannot modify accepted Booking!'),
                                  duration: Duration(seconds: 3),
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

  void _showModifyDialog(
      BuildContext context, Map<String, dynamic> booking) async {
    final TextEditingController modifyDateController =
    TextEditingController(text: booking['bookingDate']);
    DateTime selectedDate = DateTime.parse(booking['bookingDate']);

    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (newDate != null) {
      TimeOfDay? newTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate),
      );

      if (newTime != null) {
        final DateTime combinedDateTime = DateTime(
          newDate.year,
          newDate.month,
          newDate.day,
          newTime.hour,
          newTime.minute,
        );

        String formattedDate =
        DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);
        modifyDateController.text = formattedDate;

        await _controller.updateBookingDate(
          booking['_id'].toHexString(),
          formattedDate,
        );
        await _controller.updateBookingStatus(
          booking['_id'].toHexString(),
          'Modified',
        );

        setState(() {});
        Navigator.pop(context);
      }
    }
  }
}