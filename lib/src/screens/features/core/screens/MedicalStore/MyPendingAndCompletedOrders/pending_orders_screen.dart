import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabChat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'ordered_medicines_card.dart';
import 'pending_orders_screen_controller.dart';

class PendingOrdersScreen extends StatefulWidget {
  final String storeEmail;

  const PendingOrdersScreen({super.key, required this.storeEmail});

  @override
  _PendingOrdersScreenState createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  final PendingAndCompletedOrdersController _controller = PendingAndCompletedOrdersController();
  late Future<List<Map<String, dynamic>>> _pendingOrdersFuture;
  late Future<List<Map<String, dynamic>>> _preparingOrdersFuture;
  String _currentTab = 'pending';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _pendingOrdersFuture = _controller.getPendingOrders(widget.storeEmail);
      _preparingOrdersFuture = _controller.getPreparingOrders(widget.storeEmail);
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

  Future<void> _acceptOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Acceptance'),
        content: const Text('Are you sure you want to accept this order?'),
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
      final success = await _controller.acceptOrder(orderId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order accepted successfully')),
        );
        _loadOrders();
      }
    }
  }

  Future<void> _completeOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: const Text('Mark this order as delivered?'),
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
      final success = await _controller.completeOrder(orderId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order marked as delivered')),
        );
        _loadOrders();
      }
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rejection'),
        content: const Text('Are you sure you want to reject this order?'),
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
          const SnackBar(content: Text('Order rejected successfully')),
        );
        _loadOrders();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Store Orders'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _currentTab = index == 0 ? 'pending' : 'preparing';
              });
            },
            tabs: const [
              Tab(text: 'Pending Orders'),
              Tab(text: 'Preparing Orders'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrdersList(_pendingOrdersFuture, 'pending'),
            _buildOrdersList(_preparingOrdersFuture, 'preparing'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(Future<List<Map<String, dynamic>>> future, String status) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
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
                  'No ${status == 'pending' ? 'pending' : 'preparing'} orders found.',
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
                  showActions: true,
                  onAccept: () => _acceptOrder(order['_id'].toString()),
                  onComplete: () => _completeOrder(order['_id'].toString()),
                  onCancel: () => _cancelOrder(order['_id'].toString()),
                );
              },
            );
          }
          return const Center(child: Text('No orders found.'));
        },
      ),
    );
  }
}