import 'package:bson/bson.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/MyBookings/rating_controller.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/patient_bookings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../repository/user_repository/user_repository.dart';
import '../../../../../../stripe/stripe_services.dart';
import '../../../../authentication/models/chat_user_model.dart';
import '../PatientChat/chat_screen.dart';
import '../PatientControllers/my_bookings_controller.dart';
import 'MyBooking_widgets/labPaymentSummaryCard.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  _MyBookingsScreenState createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final MyBookingsController _controller = MyBookingsController();
  final Map<ObjectId, bool> _hasRatingCache = {};
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookingsAndRatings();
  }

  Future<void> _loadBookingsAndRatings() async {
    try {
      final bookings = await _controller.fetchUserBookings();
      final ratingStatuses = await Future.wait(
        bookings.map((b) => _checkIfRatingExists(b['_id'])),
      );

      setState(() {
        _bookings = bookings;
        for (int i = 0; i < bookings.length; i++) {
          _hasRatingCache[bookings[i]['_id']] = ratingStatuses[i];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to load bookings: ${e.toString()}');
    }
  }

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
    ) ?? false;
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
              child: RefreshIndicator(
                onRefresh: _loadBookingsAndRatings,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _bookings.isEmpty
                    ? Center(
                  child: Text(
                    'No bookings found.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDarkTheme ? Colors.white54 : Colors.black54,
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    final price = booking['price']?.toString() ?? '0.0';
                    final bookingId = booking['_id'];
                    final hasRating = _hasRatingCache[bookingId] ?? false;
                    final canRate = booking['status'] == 'Completed' && !hasRating;

                    return PatientBookingsCard(
                      labUserName: booking['labUserName'] ?? 'Unknown Lab',
                      testName: booking['testName'] ?? 'Unknown Test',
                      bookingDate: formatDate(
                          booking['bookingDate'] ??  DateTime.now().toUtc().add(Duration(hours:5)).toString()),
                      status: booking['status'] ?? 'Pending',
                      price: price,
                      isDark: isDarkTheme,
                      onAccept: () => _handleAccept(booking),
                      onReject: () => _handleReject(booking),
                      onModify: () => _handleModify(booking),
                      onMessage: () => _handleMessage(booking),
                      onComplete: ()=> _handleComplete(booking),
                      hasRating: hasRating,
                      onRate: canRate
                          ? () => _showRatingDialog(
                        context,
                        booking['labUserEmail'],
                        booking['patientUserEmail'],
                        bookingId,
                      )
                          : null,
                      showAcceptButton: booking['status'] == 'Modified' &&
                          booking['lastModifiedBy'] == 'lab', bookingId: '',
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkIfRatingExists(ObjectId bookingId) async {
    if (_hasRatingCache.containsKey(bookingId)) {
      return _hasRatingCache[bookingId]!;
    }
    final hasRating = await RatingsController.hasRatingForBooking(bookingId);
    _hasRatingCache[bookingId] = hasRating;
    return hasRating;
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
        await _loadBookingsAndRatings();
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
        await _loadBookingsAndRatings();
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

  Future<void> _handleComplete(Map<String, dynamic> booking) async {

    final confirmed = await _showConfirmationDialog(
      context,
      'Complete Booking',
      'Are you sure you want to complete the booking?',
      Icons.edit_calendar,
    );
    if (confirmed) {
      if (booking['status'] == "Accepted") {
        final totalAmount=booking['price'];
        double price= double.parse(totalAmount);

        final paymentMethod = await _showMedicinePaymentMethodDialog(price);
        if (paymentMethod == null) return;

        bool paymentSuccess = true;

        if (paymentMethod == 'online') {
          paymentSuccess = await _processStripePayment(price);
          if (!paymentSuccess) return;
        }
        final bookingId= booking['bookingId'];
        final success = await _controller.completeLabBooking(bookingId, 'Completed');
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine order completed successfully')),
          );
    }
  } else {
  _showSnackBar('Booking is accepted, you cannot modify this booking');
  }



  }
    }

  Future<bool> _processStripePayment(double amount) async {
    try {
      // Initialize Stripe if not already done
      await StripeService.instance.initialize();

      // Show processing dialog
      _showPaymentProcessing();

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

  Future<String?> _showMedicinePaymentMethodDialog(double amount) async {
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
                'Pay for Medicine Order',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColorLight,
                ),
              ),
              const SizedBox(height: 16),
              LabPaymentSummaryCard(amount: amount),
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
                icon: Icons.local_pharmacy,
                color: Colors.green,
                title: 'Cash payment',
                subtitle: 'Pay at hand',
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
      splashColor: Colors.deepPurple.withOpacity(0.1),
      highlightColor: Colors.deepPurple.withOpacity(0.05),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentProcessing() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Processing payment...',
                style: TextStyle(
                  color: Theme.of(context).primaryColorLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    DateTime selectedDate = DateTime.tryParse(booking['bookingDate']) ??  DateTime.now().toUtc().add(Duration(hours:5));

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

        await _loadBookingsAndRatings();
      }
    }
  }

  void _showRatingDialog(BuildContext context, String labEmail, String patientEmail, ObjectId bookingId) {
    double rating = 3.0;
    final TextEditingController reviewController = TextEditingController();
    bool isSubmitting = false;

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
                onRatingUpdate: (newRating) => rating = newRating,
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
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                final review = reviewController.text.trim();
                if (review.isEmpty) {
                  _showSnackBar('Please write a review before submitting');
                  return;
                }

                setState(() => isSubmitting = true);

                final success = await RatingsController.submitRating(
                  labEmail: labEmail,
                  userEmail: patientEmail,
                  rating: rating,
                  review: review,
                  bookingId: bookingId,
                );

                if (mounted) {
                  setState(() => isSubmitting = false);
                  if (success) {
                    _hasRatingCache[bookingId] = true;
                    Navigator.pop(context);
                    _showSnackBar('Thanks for your rating!');
                    await _loadBookingsAndRatings();
                  } else {
                    _showSnackBar('This booking has already been rated');
                  }
                }
              },
              child: isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Submit'),
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