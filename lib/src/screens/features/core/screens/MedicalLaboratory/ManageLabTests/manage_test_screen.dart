import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../constants/text_strings.dart';
import '../MedicalLabWidgets/test_service_card.dart';
import '../MedicalLabWidgets/custom_button.dart';
import 'manage_test_controller.dart';

class ManageTestServicesScreen extends StatefulWidget {
  const ManageTestServicesScreen({super.key});

  @override
  _ManageTestServicesScreenState createState() => _ManageTestServicesScreenState();
}

class _ManageTestServicesScreenState extends State<ManageTestServicesScreen> {
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _prizeController = TextEditingController();
  final TestServiceController _controller = TestServiceController();
  String _selectedTestService = '';

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
            DropdownButton<String>(
              value: _selectedTestService.isEmpty ? null : _selectedTestService,
              hint: Text('Select a Test Service'),
              icon: Icon(Icons.arrow_downward),
              iconSize: 24,
              elevation: 16,
              style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
              underline: Container(
                height: 2,
                color: isDarkTheme ? Colors.white70 : Colors.grey[200],
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTestService = newValue!;
                  _serviceNameController.text = _selectedTestService;
                });
              },
              items: testServices.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _prizeController,
              label: 'Enter Prize Amount',
              hint: 'E.g., 1500.00',
              icon: Icons.attach_money,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              isDark: isDarkTheme,
            ),
            const SizedBox(height: 16),
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
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Confirm Delete"),
                                  content: const Text("Are you sure you want to delete this test service?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text("No"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _controller.removeTestService(context, service['serviceName']).then((_) {
                                          setState(() {});
                                        });
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text("Yes"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onEdit: () {
                            _showEditServiceDialog(service['serviceName'], service['prize']);
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

  void _showEditServiceDialog(String oldServiceName, double oldPrize) {
    final TextEditingController editNameController = TextEditingController(text: oldServiceName);
    final TextEditingController editPrizeController = TextEditingController(text: oldPrize.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Test Service"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editNameController,
                decoration: const InputDecoration(labelText: "Service Name"),
                autofocus: true,
              ),
              TextField(
                controller: editPrizeController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Price"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = editNameController.text.trim();
                final newPrize = double.tryParse(editPrizeController.text.trim());

                if (newName.isEmpty || newPrize == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter valid values'),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                  return;
                }

                try {
                  await _controller.editTestService(
                    oldServiceName: oldServiceName,
                    newName: newName,
                    newPrize: newPrize,
                  );

                  // Clear fields and refresh data
                  _serviceNameController.clear();
                  _prizeController.clear();
                  setState(() {
                    _selectedTestService = '';
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"$newName" updated successfully'),
                      backgroundColor: Colors.green.shade600,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating service: ${e.toString()}'),
                      backgroundColor: Colors.red.shade600,
                    ),
                  );
                } finally {
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Save Changes"),
            ),
          ],
        );
      },
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // Allows only positive numbers and decimals
      ]
          : [],
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
      validator: (value) {
        if (keyboardType == TextInputType.number && value != null) {
          final number = double.tryParse(value);
          if (number == null || number < 0) {
            return 'Please enter a valid non-negative number';
          }
        }
        return null;
      },
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}