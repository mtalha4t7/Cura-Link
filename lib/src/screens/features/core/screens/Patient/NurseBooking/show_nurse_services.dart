import 'package:flutter/material.dart';
import 'nurse_booking.dart';

class ShowNurseServices extends StatelessWidget {
  ShowNurseServices({super.key});

  final List<Map<String, dynamic>> _services = const [
    {
      'title': 'Vital Signs Monitoring',
      'items': [
        'Blood pressure',
        'Pulse rate',
        'Temperature',
        'Blood glucose levels',
      ],
    },
    {
      'title': 'Medication Administration',
      'items': [
        'Oral medications',
        'IV/injection administration',
        'Insulin administration',
        'Pain management',
      ],
    },
    {
      'title': 'Wound Care',
      'items': [
        'Dressing of wounds/ulcers',
        'Stitches/suture removal',
        'Infection control',
      ],
    },
    {
      'title': 'Post-Operative Care',
      'items': [
        'Monitoring recovery',
        'Mobility and hygiene support',
        'Pain and medication management',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nurse Services')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          final serviceTitle = service['title'] as String;
          final subItems = service['items'] as List<String>;

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                serviceTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: subItems.map((subItem) => InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NurseBookingScreen(
                              selectedService: subItem,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_forward_ios, size: 16),
                            const SizedBox(width: 12),
                            Text(
                              subItem,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}