import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabChat/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'my_bookings_nurse_card.dart';
import 'my_bookins_screen_controller.dart';

class MyBookingsNurseScreen extends StatefulWidget {
  const MyBookingsNurseScreen({super.key});

  @override
  _MyBookingsNurseScreenState createState() => _MyBookingsNurseScreenState();
}

class _MyBookingsNurseScreenState extends State<MyBookingsNurseScreen> {
  final MyBookingsNurseController _controller = MyBookingsNurseController();
  late Future<List<Map<String, dynamic>>> _bookingsFuture;
  String _currentFilter = 'upcoming';
  String? email;

  @override
  void initState() {
    super.initState();
    _initializeAsyncStuff();
  }

  void _initializeAsyncStuff() async {
    email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      _loadBookings();
    }
  }

  void _loadBookings() {
    setState(() {
      _bookingsFuture = _currentFilter == 'upcoming'
          ? _controller.getUpcomingBookings(email!)
          : _controller.getPastBookings(email!);
    });
  }

  String _formatDate(dynamic date) {
    try {
      if (date is String) {
        return DateFormat.yMMMMEEEEd().add_jm().format(DateTime.parse(date));
      } else if (date is DateTime) {
        return DateFormat.yMMMMEEEEd().add_jm().format(date);
      }
      return 'Date not available';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _launchMaps(dynamic location) async {
    try {
      String coordinates;

      // Handle different location formats
      if (location is String) {
        coordinates = location;
      } else if (location is Map<String, dynamic>) {
        if (location['coordinates'] is List) {
          coordinates = '${location['coordinates'][1]},${location['coordinates'][0]}';
        } else {
          throw Exception('Invalid location format');
        }
      } else {
        throw Exception('Unknown location type');
      }

      final parts = coordinates.split(',');
      if (parts.length == 2) {
        final lat = parts[0].trim();
        final lng = parts[1].trim();
        final Uri uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
        );
        if (!await launchUrl(uri)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open maps')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid location coordinates')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening maps')),
        );
      }
    }
  }

  Future<void> _startChat(String patientEmail) async {
    final user = await _controller.fetchUserData(patientEmail);
    if (user != null && mounted) {
      Get.to(() => ChatScreen(user: user));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not fetch user data for chat')),
      );
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
      if (success) {
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
                DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                DropdownMenuItem(value: 'past', child: Text('Past')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentFilter = value;
                    if (email != null) {
                      _loadBookings();
                    }
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
        child: email == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else if (snapshot.hasData) {
                    final bookings = snapshot.data!..sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));

                    if (bookings.isEmpty) {
                      return Center(
                        child: Text(
                          'No $_currentFilter appointments found.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isDarkTheme
                                ? Colors.white70
                                : Colors.black54,
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
                        final patientEmail = booking['patientEmail'] as String? ?? '';
                        final location = booking['location'];
                        final bookingDate = booking['updatedAt'] ?? booking['createdAt'];
                        final bookingId = booking['_id']?.toString() ?? '';

                        return NurseBookingCard(
                          booking: booking,
                          isDark: isDarkTheme,
                          onChat: () => _startChat(patientEmail),
                          onLocation: () => _launchMaps(location),
                          formattedDate: _formatDate(bookingDate),
                          showActions: _currentFilter == 'upcoming',
                          onCancel: () => _cancelBooking(bookingId),
                          onComplete: () => _completeBooking(bookingId),
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
