import 'package:flutter/material.dart';
 // Make sure this import path is correct

class MyBookedNursesCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final bool isDark;
  final VoidCallback onChat;
  final VoidCallback onLocation;
  final String formattedDate;
  final bool showActions;

  final VoidCallback onCancel;
  final VoidCallback onComplete;
  final VoidCallback onRate;

  const MyBookedNursesCard({
    super.key,
    required this.booking,
    required this.isDark,
    required this.onChat,
    required this.onLocation,
    required this.formattedDate,
    required this.showActions,
    required this.onCancel,
    required this.onComplete,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompleted = booking['status'].toString().toLowerCase() == 'completed';

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
              // Header with nurse name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking['nurseName'] ?? 'Nurse',
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

              // Service Type
              Text(
                booking['serviceName'] ?? "",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 16),

              // Details Section
              _buildDetailRow(
                icon: Icons.calendar_today_outlined,
                title: 'Appointment Date',
                value: formattedDate,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                icon: Icons.access_time_outlined,
                title: 'Price',
                value: booking['price'].toString(),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Column(
                children: [
                  // Primary Actions (Chat and Location)
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context: context,
                          icon: Icons.chat_bubble_outline,
                          label: 'Message Nurse',
                          onPressed: onChat,
                          backgroundColor: colorScheme.primaryContainer,
                          textColor: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          context: context,
                          icon: Icons.map_outlined,
                          label: 'View Location',
                          onPressed: onLocation,
                          backgroundColor: colorScheme.secondaryContainer,
                          textColor: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Conditional Action Buttons
                  if (showActions)
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            icon: Icons.cancel_outlined,
                            label: 'Cancel Booking',
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
                  if (!showActions && isCompleted)
                    _buildActionButton(
                      context: context,
                      icon: Icons.star_outline,
                      label: 'Rate Service',
                      onPressed: onRate,
                      backgroundColor: Colors.deepPurple.withValues(),
                      textColor: Colors.white,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Existing helper methods remain unchanged
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
      case 'accepted':
      case 'confirmed':
        return Colors.blue;
      case 'completed':
      case 'fulfilled':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      case 'in progress':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}