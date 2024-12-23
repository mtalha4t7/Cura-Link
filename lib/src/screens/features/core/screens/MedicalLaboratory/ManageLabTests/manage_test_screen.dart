import 'package:flutter/material.dart';
import 'manage_test_controller.dart';

class ManageTestServicesScreen extends StatefulWidget {
  @override
  _ManageTestServicesScreenState createState() =>
      _ManageTestServicesScreenState();
}

class _ManageTestServicesScreenState extends State<ManageTestServicesScreen> {
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _prizeController = TextEditingController();
  final TestServiceController _controller = TestServiceController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
        appBar: AppBar(
        title: const Text('Manage Test Services'),
    leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
    Navigator.pop(context);
    },
    ),
    ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Manage Test Services",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // TextField to enter service name
            _buildTextField(
              controller: _serviceNameController,
              label: 'Enter Test Service',
              hint: 'E.g., Blood Test',
              icon: Icons.medical_services,
              isDark: isDarkTheme,
            ),
            const SizedBox(height: 16),

            // TextField to enter prize
            _buildTextField(
              controller: _prizeController,
              label: 'Enter Prize Amount',
              hint: 'E.g., 1500.00',
              icon: Icons.attach_money,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              isDark: isDarkTheme,
            ),
            const SizedBox(height: 16),

            // Add Service Button
            CustomButton(
              text: 'Add Service',
              isDark: isDarkTheme,
              onPressed: () {
                final serviceName = _serviceNameController.text.trim();
                final prizeText = _prizeController.text.trim();
                if (serviceName.isNotEmpty && prizeText.isNotEmpty) {
                  final prize = double.tryParse(prizeText);
                  if (prize != null) {
                    _controller.addTestService(serviceName, prize).then((_) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Service added successfully!'),
                        ),
                      );
                    });
                    _serviceNameController.clear();
                    _prizeController.clear();
                  } else {
                    _showErrorSnackbar(context, 'Invalid prize amount.');
                  }
                } else {
                  _showErrorSnackbar(context, 'Please fill in all fields.');
                }
              },
            ),
            const SizedBox(height: 16),

            // List of Services
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _controller.fetchUserServices(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else if (snapshot.hasData) {
                    final services = snapshot.data!;
                    if (services.isEmpty) {
                      return Center(
                        child: Text(
                          'No services added yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDarkTheme ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return TestServiceCard(
                          serviceName: service['serviceName'],
                          prize: service['prize'],
                          isDark: isDarkTheme,
                          onDelete: () {
                            _controller.removeTestService(service['serviceName'])
                                .then((_) {
                              setState(() {});
                            });
                          },
                        );
                      },
                    );
                  } else {
                    return Center(child: Text('No data found.'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey[200],
        labelStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class TestServiceCard extends StatelessWidget {
  final String serviceName;
  final double prize;
  final bool isDark;
  final VoidCallback onDelete;

  const TestServiceCard({
    required this.serviceName,
    required this.prize,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prize: ${prize.toStringAsFixed(2)} RS',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isDark;

  CustomButton({
    required this.text,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.blueGrey[700]!, Colors.blueGrey[800]!]
                : [Colors.blue, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
