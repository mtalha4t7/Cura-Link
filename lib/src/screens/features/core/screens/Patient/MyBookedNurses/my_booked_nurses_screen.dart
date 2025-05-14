import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabChat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../stripe/stripe_services.dart';
import 'my_booked_nurses_card.dart';
import 'my_booked_nurses_screen_controller.dart';
import 'payment_summary_card.dart';


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

  @override
  void initState() {
    super.initState();
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
    try {
      final totalAmount = await _calculateBookingAmount(bookingId);
      debugPrint('Booking amount: $totalAmount');

      if (totalAmount <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid booking amount')),
          );
        }
        return;
      }

      final paymentMethod = await _showPaymentMethodDialog(totalAmount);
      if (paymentMethod == null) return;

      bool paymentSuccess = true;

      if (paymentMethod == 'online') {
        paymentSuccess = await _processStripePayment(totalAmount);
        if (!paymentSuccess) return;
      }

      final success = await _controller.completeBooking(bookingId, paymentMethod);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking marked as completed')),
        );
        _loadBookings();
      }
    } catch (e) {
      debugPrint('Error in completeBooking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<bool> _processStripePayment(double amount) async {
    try {
      // Initialize Stripe if not already done
      await StripeService.instance.initialize();

      // Show processing dialog
      PaymentSummaryCard(amount: amount);

      // Process payment
      final success = await StripeService.instance.makePayment(amount.toInt());

      if (mounted) Navigator.pop(context); // Close processing dialog

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment failed. Please try again.')),
          );
        }
        return false;
      }
      return true;
    } on StripeException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stripe Error: ${e.error.localizedMessage}')),
        );
      }
      return false;
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Error: ${e.toString()}')),
        );
      }
      return false;
    }
  }
  Future<double> _calculateBookingAmount(String bookingId) async {
    try {
      final booking = await _controller.getBookingDetails(bookingId);
      if (booking != null && booking['price'] != null) {
        return booking['price'].toDouble();
      }
      return 0.0; // Default value if price not found
    } catch (e) {
      return 0.0; // Fallback value
    }
  }

  Future<String?> _showPaymentMethodDialog(double amount) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColorLight,
                ),
              ),
              const SizedBox(height: 16),
              PaymentSummaryCard(amount: amount),
              const SizedBox(height: 20),
              _buildPaymentOption(
                context,
                icon: Icons.credit_card,
                color: Colors.blue,
                title: 'Credit/Debit Card',
                subtitle: 'Secure online payment',
                value: 'online',
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                context,
                icon: Icons.money,
                color: Colors.green,
                title: 'Cash Payment',
                subtitle: 'Pay in person',
                value: 'cash',
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String title,
        required String subtitle,
        required String value,
      }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pop(context, value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }





  Future<void> _showRatingDialog(Map<String, dynamic> booking) async {
    final bookingId = booking['_id'].toString();
    final alreadyRated = await _controller.hasRatingForBooking(bookingId);

    if (alreadyRated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already rated this booking')),
      );
      return;
    }

    double rating = 0;
    final TextEditingController reviewController = TextEditingController();
    bool isSubmitting = false;

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
                        onTap: () => setState(() => rating = index + 1.0),
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
                      setState(() => isSubmitting = true);

                      final success = await _controller.submitRating(
                        bookingId: bookingId,
                        nurseEmail: booking['nurseEmail'],
                        userEmail: widget.patientEmail,
                        rating: rating,
                        review: reviewController.text,
                      );

                      if (mounted) {
                        setState(() => isSubmitting = false);

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Thank you for your rating!')),
                          );
                          Navigator.pop(context);
                          _loadBookings();
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a rating')),
                      );
                    }
                  },
                  child: isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Submit'),
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
                DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                DropdownMenuItem(value: 'past', child: Text('Past')),
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
              _currentFilter == 'upcoming' ? "Upcoming Appointments" : "Past Appointments",
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _bookingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'No ${_currentFilter} appointments found.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDarkTheme ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    );
                  }

                  final bookings = snapshot.data!;
                  return ListView.separated(
                    itemCount: bookings.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      final bookingId = booking['_id'].toString();

                      return FutureBuilder<bool>(
                        future: _controller.hasRatingForBooking(bookingId),
                        builder: (context, ratingSnapshot) {
                          final hasRated = ratingSnapshot.data ?? false;

                          return MyBookedNursesCard(
                            booking: booking,
                            isDark: isDarkTheme,
                            onChat: () => _startChat(booking['nurseEmail']),
                            onLocation: () => _launchMaps(booking['address']),
                            formattedDate: _formatDate(booking['createdAt']),
                            showActions: _currentFilter == 'upcoming',
                            onCancel: () => _cancelBooking(bookingId),
                            onComplete: () => _completeBooking(bookingId),
                            onRate: () => _showRatingDialog(booking),
                            hasRated: hasRated,
                          );
                        },
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
}