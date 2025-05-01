import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'my_bookins_screen_controller.dart';


class MyBookingsNurseScreen extends StatefulWidget {
  final String nurseEmail;

  const MyBookingsNurseScreen({super.key, required this.nurseEmail});

  @override
  _MyBookingsNurseScreenState createState() => _MyBookingsNurseScreenState();
}

class _MyBookingsNurseScreenState extends State<MyBookingsNurseScreen> {
  final MyBookingsNurseController _controller = MyBookingsNurseController();
  late Future<List<Map<String, dynamic>>> _bookingsFuture;
  String _currentFilter = 'upcoming'; // 'upcoming' or 'past'

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    setState(() {
      _bookingsFuture = _currentFilter == 'upcoming'
          ? _controller.getUpcomingBookings(widget.nurseEmail)
          : _controller.getPastBookings(widget.nurseEmail);
    });
  }

  // Function to format date
  String formatDate(String rawDate) {
    try {
      final parsedDate = DateTime.parse(rawDate);
      return DateFormat.yMMMMEEEEd().add_jm().format(parsedDate);
    } catch (e) {
      return rawDate;
    }
  }

  // Function to launch Google Maps
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

  // Function to initiate chat
  void _startChat(String patientId, String patientName) {
    // Implement your chat functionality here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat with $patientName'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Function to cancel booking
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

    if (confirmed == true) {
      final success = await _controller.cancelBooking(bookingId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
        _loadBookings();
      }
    }
  }

  // Function to complete booking
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
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return _NurseBookingCard(
                          booking: booking,
                          isDark: isDarkTheme,
                          onChat: () => _startChat(
                            booking['patientId'],
                            booking['patientName'],
                          ),
                          onLocation: () => _launchMaps(booking['address']),
                          formattedDate: formatDate(booking['bookingDate']),
                          showActions: _currentFilter == 'upcoming',
                          onCancel: () => _cancelBooking(booking['_id'].toHexString()),
                          onComplete: () => _completeBooking(booking['_id'].toHexString()),
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
}

class _NurseBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final bool isDark;
  final VoidCallback onChat;
  final VoidCallback onLocation;
  final String formattedDate;
  final bool showActions;
  final VoidCallback onCancel;
  final VoidCallback onComplete;

  const _NurseBookingCard({
    required this.booking,
    required this.isDark,
    required this.onChat,
    required this.onLocation,
    required this.formattedDate,
    this.showActions = false,
    required this.onCancel,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking['patientName'] ?? 'Patient',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking['status']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking['status'] ?? 'Pending',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              booking['serviceType'] ?? 'Nursing Service',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today, formattedDate),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, booking['duration'] ?? '1 hour'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, booking['address'] ?? 'No address provided'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.chat,
                  label: 'Chat',
                  onPressed: onChat,
                ),
                _buildActionButton(
                  context,
                  icon: Icons.map,
                  label: 'Location',
                  onPressed: onLocation,
                ),
                if (showActions)
                  _buildActionButton(
                    context,
                    icon: Icons.cancel,
                    label: 'Cancel',
                    onPressed: onCancel,
                    backgroundColor: Colors.red,
                  ),
                if (showActions)
                  _buildActionButton(
                    context,
                    icon: Icons.check_circle,
                    label: 'Complete',
                    onPressed: onComplete,
                    backgroundColor: Colors.green,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onPressed,
        Color? backgroundColor,
      }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onPressed,
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in progress':
        return Colors.orange;
      case 'scheduled':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}