import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabChat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'my_booked_nurses_card.dart';
import 'my_booked_nurses_screen_controller.dart';

class MyBookedNursesScreen extends StatefulWidget {
  final String patientEmail;

  const MyBookedNursesScreen({super.key, required this.patientEmail});

  @override
  _MyBookedNursesScreenState createState() => _MyBookedNursesScreenState();
}

class _MyBookedNursesScreenState extends State<MyBookedNursesScreen> {
  final MyBookedNursesController _controller = MyBookedNursesController();
  late Future<List<Map<String, dynamic>>> _bookingsFuture;
  String _currentFilter = 'upcoming';
  late final String email;

  @override
  void initState() {
    super.initState();
    email = widget.patientEmail;
    _loadBookings();
  }

  void _loadBookings() {
    setState(() {
      _bookingsFuture = _currentFilter == 'upcoming'
          ? _controller.getUpcomingBookings(widget.patientEmail)
          : _controller.getPastBookings(widget.patientEmail);
    });
  }

  String _formatDate(String rawDate) {
    try {
      final parsedDate = DateTime.parse(rawDate);
      return DateFormat.yMMMMEEEEd().add_jm().format(parsedDate);
    } catch (e) {
      return rawDate;
    }
  }

  Future<void> _launchMaps(String address) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }

  Future<void> _startChat(String nurseEmail) async {
    final user = await _controller.fetchUserData(nurseEmail);
    if (user != null && mounted) {
      Get.to(() => ChatScreen(user: user));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch user data for chat')),
        );
      }
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await _controller.cancelBooking(bookingId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
        _loadBookings();
      }
    }
  }

  Future<void> _completeBooking(String bookingId) async {
    final success = await _controller.completeBooking(bookingId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking marked as completed')),
      );
      _loadBookings();
    }
  }

  Future<void> _showRatingDialog(Map<String, dynamic> booking) async {
    double rating = 0;
    TextEditingController reviewController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Rate Your Experience'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How would you rate this service?'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            rating = index + 1.0;
                          });
                        },
                        child: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reviewController,
                    decoration: const InputDecoration(
                      labelText: 'Your review (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (rating > 0) {
                      final success = await _controller.submitRating(
                        bookingId: booking['_id'].toString(),
                        nurseEmail: booking['nurseEmail'],
                        userEmail: widget.patientEmail,
                        rating: rating,
                        review: reviewController.text,
                      );

                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thank you for your rating!')),
                        );
                        Navigator.pop(context);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a rating')),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              value: _currentFilter,
              items: const [
                DropdownMenuItem(
                  value: 'upcoming',
                  child: Text('Upcoming'),
                ),
                DropdownMenuItem(
                  value: 'past',
                  child: Text('Past'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentFilter = value;
                    _loadBookings();
                  });
                }
              },
              underline: Container(),
              icon: const Icon(Icons.filter_list),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentFilter == 'upcoming'
                  ? "Upcoming Appointments"
                  : "Past Appointments",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _bookingsFuture,
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
                          'No ${_currentFilter} appointments found.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isDarkTheme ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: bookings.length,
                      separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return MyBookedNursesCard(
                          booking: booking,
                          isDark: isDarkTheme,
                          onChat: () => _startChat(booking['nurseEmail']),
                          onLocation: () => _launchMaps(booking['location']),
                          formattedDate: _formatDate(booking['createdAt']),
                          showActions: _currentFilter == 'upcoming',
                          onCancel: () => _cancelBooking(booking['_id'].toString()),
                          onComplete: () => _completeBooking(booking['_id'].toString()),
                          onRate: () => _showRatingDialog(booking),
                        );
                      },
                    );
                  }
                  return const Center(child: Text('No data found.'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}