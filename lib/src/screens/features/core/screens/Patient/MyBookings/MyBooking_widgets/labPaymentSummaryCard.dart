import 'package:flutter/material.dart';

class LabPaymentSummaryCard extends StatelessWidget {
  final double amount;
  final String currencySymbol;

  const LabPaymentSummaryCard({
    super.key,
    required this.amount,
    this.currencySymbol = 'Rs',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'LAB TEST PAYMENT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).primaryColorLight,
              ),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Test Amount:'),
                Text(
                  '$currencySymbol ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(thickness: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Payable:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$currencySymbol ${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).primaryColorLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}