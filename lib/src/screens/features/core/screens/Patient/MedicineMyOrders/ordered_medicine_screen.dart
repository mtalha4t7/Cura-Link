import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabChat/chat_screen.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/MedicineMyOrders/payment_summary_card2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../stripe/stripe_services.dart';
import '../MyBookedNurses/payment_summary_card.dart';
import 'ordered_medicines_card.dart';
import 'my_orders_Medicine_screen_controller.dart';

class MyOrdersScreenMedicine extends StatefulWidget {
  final String patientEmail;

  const MyOrdersScreenMedicine({super.key, required this.patientEmail});

  @override
  _MyOrdersScreenMedicineState createState() => _MyOrdersScreenMedicineState();
}

class _MyOrdersScreenMedicineState extends State<MyOrdersScreenMedicine> {
  final MyOrdersScreenMedicineController _controller = MyOrdersScreenMedicineController();
  late Future<List<Map<String, dynamic>>> _ordersFuture;
  String _currentFilter = 'upcoming';
  String? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _ordersFuture = _currentFilter == 'upcoming'
          ? _controller.getUpcomingOrders(widget.patientEmail)
          : _controller.getPastOrders(widget.patientEmail);
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

  Future<void> _startChat(String storeEmail) async {
    final user = await _controller.fetchUserData(storeEmail);
    if (user != null && mounted) {
      Get.to(() => ChatScreen(user: user));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch store data for chat')),
        );
      }
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: const Text('Are you sure you want to cancel this order?'),
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
      final success = await _controller.cancelOrder(orderId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully')),
        );
        _loadOrders();
      }
    }
  }

  Future<void> _completeOrder(String orderId, order) async {
    try {
      final totalAmount = await _calculateOrderAmount(orderId);
      debugPrint('Medicine order amount: $totalAmount');

      if (totalAmount <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid order amount - please contact support')),
          );
        }
        return;
      }

      final paymentMethod = await _showMedicinePaymentMethodDialog(totalAmount);
      if (paymentMethod == null) return;

      bool paymentSuccess = true;

      if (paymentMethod == 'online') {
        paymentSuccess = await _processStripePayment(totalAmount);
        if (!paymentSuccess) return;
      }

      final success = await _controller.completeOrder(orderId, paymentMethod);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine order completed successfully')),
        );
        _loadOrders();
      }
    } catch (e) {
      debugPrint('Error completing medicine order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }


  Future<double> _calculateOrderAmount(String orderId) async {
    try {
      final order = await _controller.getOrderDetails(orderId);
      if (order != null && order['finalAmount'] != null) {
        return order['finalAmount'].toDouble();
      }
      debugPrint('Order amount not found in: ${order?.keys}');
      return 0.0;
    } catch (e) {
      debugPrint('Error calculating order amount: $e');
      return 0.0;
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
              MedicinePaymentSummaryCard(amount: amount),
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
                title: 'Cash on Delivery',
                subtitle: 'Pay when collecting medicines',
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


  Future<void> _showRatingDialog(Map<String, dynamic> order) async {
    int selectedRating = 0;
    TextEditingController reviewController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate Service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How would you rate this service?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () => setState(() => selectedRating = index + 1),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(
                  labelText: 'Review (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              if (isSubmitting) const CircularProgressIndicator(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedRating > 0) {
                  setState(() => isSubmitting = true);
                  final success = await _controller.submitRating(
                    bookingId: order['_id'].toString(),
                    storeEmail: order['storeEmail'],
                    rating: selectedRating,
                    review: reviewController.text,
                  );
                  setState(() => isSubmitting = false);

                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rating submitted successfully!')),
                    );
                    _loadOrders();
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }







  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medicine Orders'),
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
                    _loadOrders();
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
                  ? "Upcoming Orders"
                  : "Past Orders",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else if (snapshot.hasData) {
                    final orders = snapshot.data!..sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
                    if (orders.isEmpty) {
                      return Center(
                        child: Text(
                          'No ${_currentFilter} orders found.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isDarkTheme ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: orders.length,
                      separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final isCompleted = order['status'].toLowerCase() == 'completed';

                        return FutureBuilder<bool>(
                          future: _controller.hasRatingForBooking(order['_id'].toString()),
                          builder: (context, snapshot) {
                            final hasRated = snapshot.data ?? false;

                            return OrderedMedicinesCard(
                              booking: order,
                              isDark: isDarkTheme,
                              onChat: () => _startChat(order['storeEmail']),
                              formattedDate: _formatDate(order['expectedDeliveryTime']),
                              showActions: _currentFilter == 'upcoming',
                              onCancel: () => _cancelOrder(order['_id'].toString()),
                              onComplete: () async {
                                if (order['status'].toLowerCase() == 'delivered') {
                                  await _completeOrder(order['_id'].toString(), order['finalAmount']);
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please wait for the store to deliver the order first'),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              },
                              showRating: _currentFilter == 'past' && isCompleted && !hasRated,
                              onRate: () => _showRatingDialog(order),
                              hasRated: hasRated,
                            );
                          },
                        );
                      },
                    );
                  }
                  return const Center(child: Text('No orders found.'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}