import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderedMedicinesCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final bool isDark;
  final VoidCallback onChat;
  final String formattedDate;
  final bool showActions;
  final VoidCallback onCancel;
  final VoidCallback onComplete;
  final bool showRating;
  final VoidCallback onRate;
  final bool hasRated;

  const OrderedMedicinesCard({
    super.key,
    required this.booking,
    required this.isDark,
    required this.onChat,
    required this.formattedDate,
    required this.showActions,
    required this.onCancel,
    required this.onComplete,
    required this.showRating,
    required this.onRate,
    required this.hasRated,
  });

  double _calculateDeliveryProgress() {
    try {
      final expectedDeliveryTime = DateTime.parse(booking['expectedDeliveryTime']);
      final createdAt = DateTime.parse(booking['createdAt']);
      final now = DateTime.now().toUtc().add(const Duration(hours: 5));

      if (now.isAfter(expectedDeliveryTime)) return 1.0;

      final totalDuration = expectedDeliveryTime.difference(createdAt).inSeconds;
      final elapsedDuration = now.difference(createdAt).inSeconds;

      return (elapsedDuration / totalDuration).clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final medicines = booking['medicines'] as List<dynamic>? ?? [];
    final prescriptionDetails = booking['prescriptionDetails']?.toString() ?? '';
    final isDelivered = booking['status']?.toLowerCase() == 'delivered';
    final progress = isDelivered ? _calculateDeliveryProgress() : 0.0;

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
                      booking['storeName'] ?? 'Unknown Store',
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
                      color: _getStatusColor(booking['status'] ?? 'Pending'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (booking['status'] ?? 'Pending').toUpperCase(),
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

              // Distance information
              if (booking['distance'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        booking['distance'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Medicines or Prescription Section
              if (medicines.isNotEmpty) ...[
                Text(
                  'Medicines:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ...medicines.map((medicine) => _buildMedicineItem(medicine)).toList(),
              ] else if (prescriptionDetails.isNotEmpty) ...[
                Text(
                  'Prescription Details:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    prescriptionDetails,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Delivery and Amount Section
              _buildDetailRow(
                icon: Icons.access_time_outlined,
                title: 'Expected Delivery',
                value: formattedDate,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                icon: Icons.attach_money_outlined,
                title: 'Total Amount',
                value: '\Rs: ${booking['finalAmount']?.toStringAsFixed(2) ?? '0.00'}',
              ),

              // Delivery progress for delivered orders
              if (isDelivered) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0 ? Colors.green : Colors.blue,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    progress == 1.0
                        ? 'Delivery completed successfully'
                        : 'Delivery in progress (${(progress * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],

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
                          label: 'Message Store',
                          onPressed: onChat,
                          backgroundColor: colorScheme.primaryContainer,
                          textColor: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (showActions)
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            icon: Icons.cancel_outlined,
                            label: 'Cancel Order',
                            onPressed: onCancel,
                            backgroundColor: colorScheme.errorContainer,
                            textColor: colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            icon: Icons.check_circle_outlined,
                            label: 'Mark Complete',
                            onPressed: onComplete,
                            backgroundColor: colorScheme.tertiaryContainer,
                            textColor: colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),

                  if (showRating)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.star_outline,
                        label: 'Rate Service',
                        onPressed: onRate,
                        backgroundColor: Colors.deepPurple[400]!,
                        textColor: Colors.white,
                      ),
                    ),

                  if (hasRated)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'Rated',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineItem(dynamic medicine) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.medical_services_outlined, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine['name'] ?? 'Unknown Medicine',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  ' ${medicine['price']?.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    required VoidCallback? onPressed,
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
      case 'cancelled':
        return Colors.red;
      case 'in progress':
        return Colors.purple;
      case 'delivered':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}