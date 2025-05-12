import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabChat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _completeOrder(String orderId) async {
    final success = await _controller.completeOrder(orderId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order marked as completed')),
      );
      _loadOrders();
    }
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
                    final orders = snapshot.data!;
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
                        return OrderedMedicinesCard(
                          booking: order,
                          isDark: isDarkTheme,
                          onChat: () => _startChat(order['storeEmail']),
                          formattedDate: _formatDate(order['expectedDeliveryTime']),
                          showActions: _currentFilter == 'upcoming',
                          onCancel: () => _cancelOrder(order['_id'].toString()),
                          onComplete: () => _completeOrder(order['_id'].toString()),
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