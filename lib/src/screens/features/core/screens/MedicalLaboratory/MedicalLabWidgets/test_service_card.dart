import 'package:flutter/material.dart';

class TestServiceCard extends StatelessWidget {
  final String serviceName;
  final double prize;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TestServiceCard({
    Key? key,
    required this.serviceName,
    required this.prize,
    required this.isDark,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? Colors.grey[900] : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Text(
          serviceName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          'Rs ${prize.toStringAsFixed(2)}',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit icon
            IconButton(
              icon: Icon(Icons.edit, color: isDark ? Colors.orangeAccent : Colors.blue),
              onPressed: onEdit,
              tooltip: 'Edit Service',
            ),
            // Delete icon
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Delete Service',
            ),
          ],
        ),
      ),
    );
  }
}
