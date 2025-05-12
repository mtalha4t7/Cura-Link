import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabChat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'ordered_medicines_card.dart';
import 'pending_orders_screen_controller.dart';

class CompletedOrdersScreen extends StatefulWidget {
  final String storeEmail;

  const CompletedOrdersScreen({super.key, required this.storeEmail});

  @override
  _CompletedOrdersScreenState createState() => _CompletedOrdersScreenState();
}

class _CompletedOrdersScreenState extends State<CompletedOrdersScreen> {
  final PendingAndCompletedOrdersController _controller = PendingAndCompletedOrdersController();
  late Future<List<Map<String, dynamic>>> _completedOrdersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _completedOrdersFuture = _controller.getCompletedOrders(widget.storeEmail);
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

  Future<void> _startChat(String patientEmail) async {
    final user = await _controller.fetchUserData(patientEmail);
    if (user != null && mounted) {
      Get.to(() => ChatScreen(user: user));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch patient data for chat')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Orders'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _completedOrdersFuture,
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
                    'No completed orders found.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDarkTheme ? Colors.white70 : Colors.black54,
                    ),
                  ),
                );
              }
              return ListView.separated(
                itemCount: orders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return OrderedMedicinesCard(
                    order: order,
                    isDark: isDarkTheme,
                    onChat: () => _startChat(order['patientEmail']),
                    formattedDate: _formatDate(order['expectedDeliveryTime']),
                    showActions: false, // No actions for completed orders
                    onAccept: () {}, // Empty callbacks
                    onComplete: () {},
                    onCancel: () {},
                  );
                },
              );
            }
            return const Center(child: Text('No orders found.'));
          },
        ),
      ),
    );
  }
}