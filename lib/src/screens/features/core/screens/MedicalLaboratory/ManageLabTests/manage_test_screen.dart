import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabWidgets/test_service_card.dart';
import 'package:flutter/material.dart';
import 'manage_test_controller.dart';

class ManageTestServicesScreen extends StatefulWidget {
  const ManageTestServicesScreen({super.key});

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
                            color:
                                isDarkTheme ? Colors.white54 : Colors.black54,
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
                            _controller
                                .removeTestService(service['serviceName'])
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
