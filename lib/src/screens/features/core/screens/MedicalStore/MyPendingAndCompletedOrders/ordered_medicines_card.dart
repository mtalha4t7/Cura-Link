import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';

class OrderedMedicinesCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isDark;
  final VoidCallback onChat;
  final String formattedDate;
  final bool showActions;
  final VoidCallback onAccept;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const OrderedMedicinesCard({
    super.key,
    required this.order,
    required this.isDark,
    required this.onChat,
    required this.formattedDate,
    required this.showActions,
    required this.onAccept,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Future<void> _launchMaps() async {
      try {
        final location = order['patientLocation'];
        if (location != null && location['coordinates'] != null) {
          final lat = location['coordinates'][0]['\$numberDouble'];
          final lng = location['coordinates'][1]['\$numberDouble'];
          final coordinates = '$lat,$lng';

          final Uri uri = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(coordinates)}',
          );

          if (!await launchUrl(uri)) {
            throw Exception('Could not launch maps');
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(content: Text('Error opening maps: ${e.toString()}')),
        );
      }
    }


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
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
                      order['patientName'] ?? 'Unknown Patient',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order['status'] ?? 'Pending'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (order['status'] ?? 'Pending').toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Location button
              InkWell(
                onTap: _launchMaps,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        'View Patient Location',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Details Section
              _buildDetailRow(
                icon: Icons.calendar_today_outlined,
                title: 'Order Date',
                value: _formatDate(order['createdAt']),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                icon: Icons.access_time_outlined,
                title: 'Expected Delivery',
                value: _formatDate(order['expectedDeliveryTime']),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                icon: Icons.attach_money_outlined,
                title: 'Total Amount',
                value: '\$${order['finalAmount']?.toStringAsFixed(2) ?? '0.00'}',
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context: context,
                          icon: Icons.chat_bubble_outline,
                          label: 'Message Patient',
                          onPressed: onChat,
                          backgroundColor: colorScheme.primaryContainer,
                          textColor: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (showActions)
                    Column(
                      children: [
                        if (order['status'] == 'Pending')
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  context: context,
                                  icon: Icons.check_circle_outline,
                                  label: 'Accept Order',
                                  onPressed: onAccept,
                                  backgroundColor: Colors.green,
                                  textColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  context: context,
                                  icon: Icons.cancel_outlined,
                                  label: 'Reject Order',
                                  onPressed: onCancel,
                                  backgroundColor: colorScheme.errorContainer,
                                  textColor: colorScheme.onErrorContainer,
                                ),
                              ),
                            ],
                          ),
                        if (order['status'] == 'Preparing')
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  context: context,
                                  icon: Icons.delivery_dining,
                                  label: 'Mark as Delivered',
                                  onPressed: onComplete,
                                  backgroundColor: Colors.teal,
                                  textColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
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
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}