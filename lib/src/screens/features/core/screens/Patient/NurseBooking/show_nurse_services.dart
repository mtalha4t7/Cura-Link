import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nurse_booking.dart';

class ShowNurseServices extends StatefulWidget {
  const ShowNurseServices({super.key});

  @override
  State<ShowNurseServices> createState() => _ShowNurseServicesState();
}

class _ShowNurseServicesState extends State<ShowNurseServices> {
  final List<Map<String, dynamic>> _allServices = const [
    {
      'title': 'Vital Signs Monitoring',
      'items': [
        {'name': 'Blood pressure', 'price': 800},
        {'name': 'Pulse rate', 'price': 500},
        {'name': 'Temperature', 'price': 500},
        {'name': 'Blood glucose levels', 'price': 1000},
      ],
    },
    {
      'title': 'Medication Administration',
      'items': [
        {'name': 'Oral medications', 'price': 1000},
        {'name': 'IV/injection administration', 'price': 1500},
        {'name': 'Insulin administration', 'price': 1200},
        {'name': 'Pain management', 'price': 2000},
      ],
    },
    {
      'title': 'Wound Care',
      'items': [
        {'name': 'Dressing of wounds/ulcers', 'price': 1500},
        {'name': 'Stitches/suture removal', 'price': 2500},
        {'name': 'Infection control', 'price': 1800},
      ],
    },
    {
      'title': 'Post-Operative Care',
      'items': [
        {'name': 'Monitoring recovery', 'price': 2500},
        {'name': 'Mobility and hygiene support', 'price': 2000},
        {'name': 'Pain and medication management', 'price': 3000},
      ],
    },
    {
      'title': 'Specialized Care',
      'items': [
        {'name': 'Elderly care', 'price': 3500},
        {'name': 'Newborn care', 'price': 4000},
        {'name': 'Palliative care', 'price': 5000},
      ],
    },
  ];

  List<Map<String, dynamic>> _filteredServices = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredServices = _allServices;
    _searchController.addListener(_filterServices);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterServices() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredServices = _allServices;
      });
      return;
    }

    setState(() {
      _filteredServices = _allServices.map((category) {
        final filteredItems = (category['items'] as List).where((item) {
          return item['name'].toString().toLowerCase().contains(query) ||
              item['price'].toString().contains(query);
        }).toList();

        return {
          'title': category['title'],
          'items': filteredItems,
        };
      }).where((category) => (category['items'] as List).isNotEmpty).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final accentColor = theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nursing Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Pricing Information'),
                  content: const Text(
                    'Prices are in Pakistani Rupees (PKR) and may vary based on service duration and complexity.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _filteredServices.length,
              itemBuilder: (context, index) {
                final service = _filteredServices[index];
                final serviceTitle = service['title'] as String;
                final subItems = service['items'] as List<dynamic>;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: cardColor,
                  child: ExpansionTile(
                    title: Text(
                      serviceTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: subItems.map((subItem) => InkWell(
                            onTap: () async {
                              final prefs = await SharedPreferences.getInstance();
                              if (prefs.containsKey('nurseRequestId')) {
                                _showExistingRequestDialog(context, prefs, subItem['name'],subItem['price']);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NurseBookingScreen(selectedServiceName: subItem['name'],selectedServicePrice: subItem['price'].toString()),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.medical_services, size: 20, color: accentColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      subItem['name'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'PKR ${subItem['price']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: accentColor,
                                      ),
                                    ),
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
          ),
        ],
      ),
    );
  }

  void _showExistingRequestDialog(BuildContext context, SharedPreferences prefs, String serviceName,String servicePrice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Request Found'),
        content: const Text('You have an ongoing service request. Would you like to resume it or start a new one?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NurseBookingScreen(selectedServiceName: '',selectedServicePrice: ''),
                ),
              );
            },
            child: const Text('Resume'),
          ),
          TextButton(
            onPressed: () async {
              await prefs.remove('nurseRequestId');
              await prefs.remove('nurseService');
              await prefs.remove('requestLat');
              await prefs.remove('requestLng');
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NurseBookingScreen(selectedServiceName: serviceName,selectedServicePrice:servicePrice),
                ),
              );
            },
            child: const Text('New Request'),
          ),
        ],
      ),
    );
  }
}