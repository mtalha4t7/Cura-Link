import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabChat/chat_screen.dart';
import 'package:cura_link/src/screens/features/core/screens/MedicalStore/MyPendingAndCompletedOrders/pending_orders_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PendingOrdersScreen extends StatefulWidget {
  final String storeEmail;

  const PendingOrdersScreen({super.key, required this.storeEmail});

  @override
  _PendingOrdersScreenState createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  final PendingAndCompletedOrdersController _controller = PendingAndCompletedOrdersController();
  Future<List<Map<String, dynamic>>>? _pendingOrdersFuture;
  Future<List<Map<String, dynamic>>>? _deliveredOrdersFuture;
  String _currentTab = 'pending';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _pendingOrdersFuture = _controller.getPendingOrders(widget.storeEmail);
      _deliveredOrdersFuture = _controller.getDeliveredOrders(widget.storeEmail);
    });
  }

  String _formatDate(String rawDate) {
    try {
      final parsedDate = DateTime.parse(rawDate);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(parsedDate);
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

  Future<void> _markAsDelivered(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: const Text('Are you sure you want to mark this order as delivered?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await _controller.updateOrderStatus(orderId, 'delivered');
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as delivered'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders();
      }
    }
  }

  double _calculateDeliveryProgress(Map<String, dynamic> order) {
    try {
      final createdAt = DateTime.parse(order['createdAt']);
      final deliveryTime = order['deliveryTime'] ?? '15 mins';
      final minutes = int.tryParse(deliveryTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 15;
      final expectedDeliveryTime = createdAt.add(Duration(minutes: minutes));
      final now =  DateTime.now().toUtc().add(Duration(hours:5));

      if (now.isAfter(expectedDeliveryTime)) return 1.0;

      final totalDuration = expectedDeliveryTime.difference(createdAt).inMinutes;
      final elapsedDuration = now.difference(createdAt).inMinutes;

      return (elapsedDuration / totalDuration).clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Medicine Orders', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            onTap: (index) {
              setState(() {
                _currentTab = index == 0 ? 'pending' : 'delivered';
              });
            },
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Delivered'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPendingOrdersList(),
            _buildDeliveredOrdersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingOrdersList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pendingOrdersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)),
            );
          } else if (snapshot.hasData) {
            final orders = snapshot.data!;
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No pending orders',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderCard(
                  order: order,
                  isPending: true,
                  onDeliver: () => _markAsDelivered(order['_id'].toString()),
                );
              },
            );
          }
          return const Center(child: Text('No orders found.'));
        },
      ),
    );
  }

  Widget _buildDeliveredOrdersList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _deliveredOrdersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)),
            );
          } else if (snapshot.hasData) {
            final orders = snapshot.data!;
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No delivered orders yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderCard(
                  order: order,
                  isPending: false,
                );
              },
            );
          }
          return const Center(child: Text('No orders found.'));
        },
      ),
    );
  }

  Widget _buildOrderCard({
    required Map<String, dynamic> order,
    required bool isPending,
    VoidCallback? onDeliver,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = isPending ? 0.0 : _calculateDeliveryProgress(order);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order['patientName'] ?? 'Customer',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['status'] ?? 'Pending').withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(order['status'] ?? 'Pending'),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    (order['status'] ?? 'Pending').toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _getStatusColor(order['status'] ?? 'Pending'),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Order details
            _buildDetailItem(Icons.calendar_today_outlined, 'Order Date', _formatDate(order['createdAt'])),
            const SizedBox(height: 8),
            _buildDetailItem(Icons.access_time_outlined, 'Expected Delivery', _formatDate(order['expectedDeliveryTime'])),
            const SizedBox(height: 8),
            _buildDetailItem(Icons.attach_money_outlined, 'Total Amount', '\$${order['finalAmount']?.toStringAsFixed(2) ?? '0.00'}'),

            if (!isPending) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress == 1.0 ? Colors.green : colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                progress == 1.0
                    ? 'Delivery completed'
                    : 'Delivery progress: ${(progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('Message'),
                    onPressed: () => _startChat(order['patientEmail']),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delivery_dining, size: 18),
                      label: const Text('Mark Delivered'),
                      onPressed: onDeliver,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}