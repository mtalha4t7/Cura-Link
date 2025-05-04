import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MedicalStoreOwnerScreen extends StatefulWidget {
  const MedicalStoreOwnerScreen({super.key});

  @override
  State<MedicalStoreOwnerScreen> createState() => _MedicalStoreOwnerScreenState();
}

class _MedicalStoreOwnerScreenState extends State<MedicalStoreOwnerScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  final _bidController = TextEditingController();

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  Future<void> _submitBid(String requestId, double originalTotal) async {
    final bidAmount = double.tryParse(_bidController.text);
    if (bidAmount == null || bidAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bid amount')),
      );
      return;
    }

    try {
      await _firestore.collection('medical_requests').doc(requestId).update({
        'status': 'bid_submitted',
        'storeBid': bidAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bid submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit bid: $e')),
      );
    }
  }

  void _showBidDialog(String requestId, double originalTotal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Bid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Original Total: PKR ${originalTotal.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: _bidController,
              decoration: const InputDecoration(
                labelText: 'Your Bid Amount (PKR)',
                prefixText: 'PKR ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitBid(requestId, originalTotal),
            child: const Text('Submit Bid'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('medical_requests')
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending requests'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final medicines = List<Map<String, dynamic>>.from(data['medicines'] ?? []);
              final createdAt = (data['createdAt'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Request #${doc.id.substring(0, 6)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            _dateFormat.format(createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Medicines:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...medicines.map((medicine) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(child: Text(medicine['name'])),
                            Text('PKR ${medicine['price']}'),
                          ],
                        ),
                      )),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            'PKR ${data['total']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (data['prescriptionImage'] != null) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Prescription Included',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showBidDialog(doc.id, data['total']),
                          child: const Text('Submit Bid'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}