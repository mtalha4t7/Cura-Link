import 'package:bson/bson.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/MyBookings/rating_controller.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/patient_bookings_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
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

    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message, style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.check),
            label: const Text('Confirm'),
          ),
        ],
      ),
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage Bookings',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>( // Fetch bookings data
                future: _controller.fetchUserBookings(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'No bookings found.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDarkTheme ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    );
                  }

                  final bookings = snapshot.data!;
                  return ListView.builder(
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      final price = booking['price']?.toString() ?? '0.0';

                      // Pass showAcceptButton based on the booking status
                      return PatientBookingsCard(
                        labUserName: booking['labUserName'] ?? 'Unknown Lab',
                        testName: booking['testName'] ?? 'Unknown Test',
                        bookingDate: formatDate(booking['bookingDate'] ?? DateTime.now().toString()),
                        status: booking['status'] ?? 'Pending',
                        price: price,
                        isDark: isDarkTheme,
                        onAccept: () => _handleAccept(booking),
                        onReject: () => _handleReject(booking),
                        onModify: () => _handleModify(booking),
                        onMessage: () => _handleMessage(booking),
                        onRate: () => _showRatingDialog(
                          context,
                          booking['labUserEmail'],
                          booking['patientUserEmail'],
                          booking['_id'],
                        ),
                        showAcceptButton: booking['status'] == 'Modified' &&
                            booking['lastModifiedBy'] == 'lab', // Show button only for 'Modified' status
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAccept(Map<String, dynamic> booking) async {
    if (booking['status'] == "Modified" && booking['lastModifiedBy'] == 'lab') {
      final confirmed = await _showConfirmationDialog(
        context,
        'Accept Booking',
        'Are you sure you want to accept this booking?',
        Icons.check_circle_outline,
      );
      if (confirmed) {
        await _controller.updateBookingStatus(
          booking['bookingId'].toString(),
          'Accepted',
          lastModifiedBy: 'patient',
        );
        setState(() {});
      }
    } else {
      _showSnackBar('You can only accept when booking is modified by Lab');
    }
  }

  Future<void> _handleReject(Map<String, dynamic> booking) async {
    if (booking['status'] != "Accepted") {
      final confirmed = await _showConfirmationDialog(
        context,
        'Cancel Booking',
        'Are you sure you want to cancel this booking?',
        Icons.cancel,
      );
      if (confirmed) {
        await _controller.rejectAndDeleteBooking(booking['bookingId']);
        setState(() {});
      }
    } else {
      _showSnackBar('Once accepted, you cannot cancel the booking');
    }
  }

  Future<void> _handleModify(Map<String, dynamic> booking) async {
    if (booking['status'] != "Accepted") {
      final confirmed = await _showConfirmationDialog(
        context,
        'Modify Booking',
        'Are you sure you want to change the booking time?',
        Icons.edit_calendar,
      );
      if (confirmed) {
        await _showModifyDialog(context, booking);
      }
    } else {
      _showSnackBar('Booking is accepted, you cannot modify this booking');
    }
  }

  Future<void> _handleMessage(Map<String, dynamic> booking) async {
    final userEmail = booking['labUserEmail']?.toString();
    if (userEmail == null) return;

    final user = await fetchUserData(userEmail);
    if (user != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen(user: user)),
      );
    } else {
      _showSnackBar('User data not found.');
    }
  }

  Future<void> _showModifyDialog(BuildContext context, Map<String, dynamic> booking) async {
    DateTime selectedDate = DateTime.tryParse(booking['bookingDate']) ?? DateTime.now();

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
          newDate.year, newDate.month, newDate.day, newTime.hour, newTime.minute,
        );

        final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);

        await _controller.updateBookingDateAndStatus(
          booking['bookingId'].toString(),
          formattedDate,
          'Modified',
          lastModifiedBy: 'patient',
        );

        setState(() {});
      }
    }
  }

  void _showRatingDialog(BuildContext context, String labEmail, String patientEmail, ObjectId bookingId) {
    double rating = 3.0;
    final TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
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
                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              child: const Text('Submit'),
              onPressed: () async {
                final review = reviewController.text.trim();
                if (review.isEmpty) {
                  _showSnackBar('Please write a review before submitting');
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
                  _showSnackBar('Thanks for your rating!');
                } catch (e) {
                  Navigator.pop(context);
                  _showSnackBar('Error: ${e.toString()}');
                }
              },
            ),
          ],
        ),
      ),
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

  void _showSnackBar(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }
}
