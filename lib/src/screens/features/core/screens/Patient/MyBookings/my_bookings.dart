import 'package:bson/bson.dart';
import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabWidgets/booking_card.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/MyBookings/rating_controller.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/patient_bookings_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../repository/user_repository/user_repository.dart';
import '../../../../authentication/models/chat_user_model.dart';
import '../PatientChat/chat_screen.dart';
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
                          labUserName: booking['labUserName'] ?? 'Unknown Lab',
                          testName: booking['testName'] ?? 'Unknown Test',
                          bookingDate: formatDate(booking['bookingDate'] ?? DateTime.now().toString()),
                          status: booking['status'] ?? 'Pending',
                          price: price,
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
                          onMessage: () async {
                            final userEmail =  booking['labUserEmail']?.toString();
                                print(userEmail);
                            if (userEmail == null) return;

                            final user = await fetchUserData(userEmail);
                            if (user != null && context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(user: user),
                                ),
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User data not found.'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          }, onRate: () {
                          _showRatingDialog(
                            context,
                            booking['labUserEmail'],
                            booking['patientUserEmail'],
                            booking['_id'], // NEW
                          );
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

  void _showRatingDialog(BuildContext context, String labEmail, String patientEmail, ObjectId bookingId) {
    double rating = 3.0;
    final TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Rate the Lab'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('How was your experience?'),
                const SizedBox(height: 10),
                RatingBar.builder(
                  initialRating: rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (newRating) {
                    setState(() {
                      rating = newRating;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reviewController,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Write your review',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('Submit'),
                onPressed: () async {
                  final review = reviewController.text.trim();
                  if (review.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please write a review before submitting')),
                    );
                    return;
                  }

                  try {
                    await RatingsController.submitRating(
                      labEmail: labEmail,
                      userEmail: patientEmail,
                      rating: rating,
                      review: review,
                      bookingId: bookingId,
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thanks for your rating!')),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }



  Future<ChatUserModelMongoDB?> fetchUserData(String email) async {
    try {
      final userData = await UserRepository.instance.getUserByEmailFromAllCollections(email);
      return userData != null ? ChatUserModelMongoDB.fromMap(userData) : null;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
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
