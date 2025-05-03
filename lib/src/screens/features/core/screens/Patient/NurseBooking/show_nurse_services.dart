import 'package:cura_link/src/screens/features/core/screens/Patient/NurseBooking/nurse_booking_controller.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
                      // In show_nurse_services.dart, modify the onTap handler:
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();

                        if (prefs.containsKey('nurseRequestId')) {
                          // Show dialog to resume or cancel existing request
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Active Request Found'),
                              content: const Text('You have an ongoing service request.'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const NurseBookingScreen(selectedService: ''),
                                      ),
                                    );
                                  },
                                  child: const Text('Resume'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    // Force clear existing request
                                    await prefs.remove('nurseRequestId');
                                    await prefs.remove('nurseService');
                                    await prefs.remove('requestLat');
                                    await prefs.remove('requestLng');
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => NurseBookingScreen(selectedService: subItem),
                                      ),
                                    );
                                  },
                                  child: const Text('New Request'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NurseBookingScreen(selectedService: subItem),
                            ),
                          );
                        }
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