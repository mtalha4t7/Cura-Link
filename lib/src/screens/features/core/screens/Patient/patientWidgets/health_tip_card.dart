import 'package:flutter/material.dart';

class HealthTipCard extends StatelessWidget {
  final String title;

  const HealthTipCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.health_and_safety, size: 40, color: Colors.green[700]),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
