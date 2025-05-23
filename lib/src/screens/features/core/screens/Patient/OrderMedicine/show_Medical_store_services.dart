import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'medicine_booking.dart';

class MedicalStoreServicesScreen extends StatefulWidget {
  const MedicalStoreServicesScreen({super.key});

  @override
  State<MedicalStoreServicesScreen> createState() =>
      _MedicalStoreServicesScreenState();
}

class _MedicalStoreServicesScreenState extends State<MedicalStoreServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final List<Map<String, dynamic>> otcMedicines =[
    {'name': 'Panadol (500mg)', 'price': 50.0, 'selected': false, 'category': 'Pain And Fever'},
    {'name': 'Disprin (300mg)', 'price': 26.91, 'selected': false, 'category': 'Pain And Fever'},
    {'name': 'Febrol (500mg)', 'price': 651.7, 'selected': false, 'category': 'Pain And Fever'},
    {'name': 'Calpol (500mg) ', 'price': 31.77, 'selected': false, 'category': 'Pain And Fever'},
    {'name': 'Rigix (10mg) ', 'price': 148.5, 'selected': false, 'category': 'All'},
    {'name': 'Laxoberon (5mg)', 'price': 57.0, 'selected': false, 'category': 'General Aids'},
    {'name': 'Alergo (10mg) ', 'price': 185.25, 'selected': false, 'category': 'All'},
    {'name': 'Gesto ', 'price': 237.5, 'selected': false, 'category': 'Gastrics'},
    {'name': 'Trisil Plus (200/200/25mg) ', 'price': 90.0, 'selected': false, 'category': 'Gastrics'},
    {'name': 'Zyrtec (10mg)', 'price': 175.77, 'selected': false, 'category': 'All'},
    {'name': 'Imodium (2mg) ', 'price': 75.22, 'selected': false, 'category': 'Gastrics'},
    {'name': 'Avil (25mg) ', 'price': 15.29, 'selected': false, 'category': 'All'},
    {'name': 'Brufen (200mg)', 'price': 41.42, 'selected': false, 'category': 'Pain And Fever'},
    {'name': 'Ascard (75mg) ', 'price': 26.64, 'selected': false, 'category': 'General Aids'},
    {'name': 'Sedil (10mg) ', 'price': 82.37, 'selected': false, 'category': 'General Aids'},
    {'name': 'Coldrex ', 'price': 42.28, 'selected': false, 'category': 'First Aid'},
    {'name': 'Ceridal (10mg)', 'price': 47.5, 'selected': false, 'category': 'All'},
    {'name': 'Loprin (150mg)', 'price': 32.13, 'selected': false, 'category': 'General Aids'},
    {'name': 'Smecta (3g) ', 'price': 33.3, 'selected': false, 'category': 'Gastrics'},
    {'name': 'Sualin ', 'price': 36.0, 'selected': false, 'category': 'Gastrics'},
    {'name': 'Dijex MP 120ml', 'price': 148.8, 'selected': false, 'category': 'Gastrics'},
    {'name': 'Cremaffin 120ml ', 'price': 135.0, 'selected': false, 'category': 'Gastrics'},
    {'name': 'Voltral Emulgel (1%) 50g Gel', 'price': 360.07, 'selected': false, 'category': 'Topicals'},
    {'name': 'Dicloran 20g Gel', 'price': 229.5, 'selected': false, 'category': 'Topicals'},
    {'name': 'Voltral Emulgel 40g Gel', 'price': 423.0, 'selected': false, 'category': 'Topicals'},
    {'name': 'Saniswab 200 Alcohol Pads', 'price': 3.8, 'selected': false, 'category': 'First Aid'},
    {'name': 'Saniplast Antiseptic (Spot) Bandage 20S', 'price': 90.0, 'selected': false, 'category': 'First Aid'},
    {'name': 'Mepore (9cm x 30cm) Dressing', 'price': 237.5, 'selected': false, 'category': 'First Aid'},
    {'name': 'Sufre Tulle ', 'price': 384.0, 'selected': false, 'category': 'First Aid'},
    {'name': 'Osmolar ORS (Banana)', 'price': 17.82, 'selected': false, 'category': 'First Aid'},
    {'name': 'Cotton (4 inch) 12 Cotton Bandages', 'price': 592.8, 'selected': false, 'category': 'First Aid'},
    {'name': 'Cotton (2 inch) 12 Cotton Bandages', 'price': 19.0, 'selected': false, 'category': 'First Aid'},
    {'name': 'Vicks VapoRub 19g Balm', 'price': 228.0, 'selected': false, 'category': 'Topicals'},
    {'name': 'First Aid (F-300) First Aid Box', 'price': 1140.0, 'selected': false, 'category': 'First Aid'},
    {'name': 'Gypsona (4in x 5yd)', 'price': 380.0, 'selected': false, 'category': 'First Aid'},
  ];

  final List<Map<String, dynamic>> prescriptionMedicines = [
    {'name': 'Augmentin', 'price': 500, 'selected': false},
    {'name': 'Tavanic', 'price': 700, 'selected': false},
    {'name': 'Amoxicillin', 'price': 300, 'selected': false},
    {'name': 'Ciprofloxacin', 'price': 400, 'selected': false},
    {'name': 'Diazepam', 'price': 250, 'selected': false},
  ];
  List<Map<String, dynamic>> get _filteredOtcMedicines {
    if (_searchQuery.isEmpty) return otcMedicines;
    return otcMedicines.where((medicine) =>
        medicine['name'].toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  List<Map<String, dynamic>> selectedMedicines = [];
  File? _prescriptionImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _updateSelectedMedicines();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateSelectedMedicines() {
    selectedMedicines = [
      ...otcMedicines.where((medicine) => medicine['selected'] == true),
      ...prescriptionMedicines.where((medicine) => medicine['selected'] == true),
    ];
  }

  Future<void> _pickPrescription() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _prescriptionImage = File(image.path);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to select image'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearPrescription() {
    setState(() {
      _prescriptionImage = null;
      for (var medicine in prescriptionMedicines) {
        medicine['selected'] = false;
      }
      _updateSelectedMedicines();
    });
  }

  void _showCheckoutDialog() {
    if (selectedMedicines.isEmpty ||
        selectedMedicines.every((m) => prescriptionMedicines.contains(m))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one OTC medicine'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final otcSelected = selectedMedicines
        .where((m) => otcMedicines.contains(m))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selected Medicines:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...otcSelected.map((medicine) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(medicine['name'])),
                  Text('PKR ${medicine['price'].toInt()}'),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'PKR ${otcSelected.fold<double>(0, (sum, item) => sum + (item['price'].toInt()))}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.to(() => MedicalStoreRequestScreen(selectedMedicines: otcSelected,));
            },
            child: const Text('Confirm Order'),
          ),
        ],
      ),
    );
  }

  void _sendPrescription() async {
    if (_prescriptionImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a prescription first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final bytes = await _prescriptionImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prescription_image', base64Image);

      Get.to(() => MedicalStoreRequestScreen(selectedMedicines: [],));
    } catch (e) {
      print('Error saving prescription image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to process prescription image'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Store'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'OTC Medicines'),
            Tab(text: 'Prescription Medicines'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMedicinesList(otcMedicines, true),
          _buildPrescriptionMedicinesList(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
        onPressed: _showCheckoutDialog,
        icon: const Icon(Icons.shopping_cart),
        label: Text('Checkout (${selectedMedicines.length})'),
      )
          : (_prescriptionImage != null
          ? FloatingActionButton.extended(
        onPressed: _sendPrescription,
        icon: const Icon(Icons.send),
        label: const Text('Send Prescription'),
      )
          : null),
    );
  }

  Widget _buildMedicinesList(List<Map<String, dynamic>> medicines, bool isOTC) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final accentColor = theme.colorScheme.secondary;

    final List<Map<String, dynamic>> displayList =
    isOTC ? _filteredOtcMedicines : medicines;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search for medicine...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final medicine = displayList[index];
              return Card(
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                child: CheckboxListTile(
                  title: Text(medicine['name'], style: TextStyle(color: textColor)),
                  subtitle: Text('PKR ${medicine['price']}',
                      style: TextStyle(color: textColor.withOpacity(0.7))),
                  value: medicine['selected'],
                  onChanged: (value) {
                    setState(() {
                      medicine['selected'] = value;
                      _updateSelectedMedicines();
                    });
                  },
                  secondary: Icon(Icons.medical_services, color: accentColor),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildPrescriptionMedicinesList() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final accentColor = theme.colorScheme.secondary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Prescription'),
                onPressed: _pickPrescription,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 8),
              if (_prescriptionImage != null)
                TextButton(
                  onPressed: _clearPrescription,
                  child: const Text('Clear Prescription'),
                ),
            ],
          ),
        ),
        if (_prescriptionImage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prescription Image:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _prescriptionImage!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
