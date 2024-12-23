import 'package:flutter/material.dart';

import '../../../../../../constants/sizes.dart';
import '../ManageLabTests/manage_test_screen.dart';
import '../MedicalLabControllers/lab_dashboard_controller.dart';
import '../MedicalLabWidgets/health_tip_card.dart';
import '../MedicalLabWidgets/medicalLab_appbar.dart';
import '../MedicalLabWidgets/medicalLab_dashboard_sidebar.dart';
import '../MedicalLabWidgets/service_card.dart';


class MedicalLabDashboard extends StatefulWidget {
  const MedicalLabDashboard({super.key});

  @override
  _MedicalLabDashboardState createState() => _MedicalLabDashboardState();
}

class _MedicalLabDashboardState extends State<MedicalLabDashboard> {
  late DashboardController _controller; // Controller instance
  bool isVerified = true;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
    _checkUserVerification();
  }

  // Method to check user verification status
  void _checkUserVerification() {
    _controller.checkUserVerification((status) {
      setState(() {
        isVerified = status;
      });
    });
  }

  // Method to verify the user based on NIC and License
  void _verifyUser(String nic, String license) {
    _controller.verifyUser(nic, license, (verificationSuccess) {
      if (verificationSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User verified successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("NIC and License verification failed.")),
        );
      }
    });
  }

  // Method to show verification dialog
  void _showVerificationDialog() {
    final nicController = TextEditingController();
    final licenseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Verify Your Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nicController,
              decoration: const InputDecoration(labelText: "NIC"),
            ),
            TextField(
              controller: licenseController,
              decoration: const InputDecoration(labelText: "License Number"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final nic = nicController.text.trim();
              final license = licenseController.text.trim();
              Navigator.of(context).pop();
              _verifyUser(nic, license);
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        appBar: MedicalLabDashboardAppBar(isDark: isDark),
        drawer: MedicalLabDashboardSidebar(isDark: isDark),
        body: Column(
          children: [
            // Show verification alert if user is not verified
            if (!isVerified)
              GestureDetector(
                onTap: _showVerificationDialog,
                child: Container(
                  color: Colors.redAccent,
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  child: const Text(
                    "Your account is not verified. Tap here to verify.",
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(tDashboardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Welcome to Cura Link Lab", style: txtTheme.bodyMedium),
                      Text("How can we assist you today?", style: txtTheme.displayMedium),
                      const SizedBox(height: tDashboardPadding),
                      const Text(
                        "Recent Bookings",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: const [
                            HealthTipCard(title: "Patient 1 - Blood Test Booking"),
                            HealthTipCard(title: "Patient 2 - COVID-19 Test Booking"),
                            HealthTipCard(title: "Patient 3 - X-Ray Booking"),
                            HealthTipCard(title: "Patient 4 - MRI Booking"),
                          ],
                        ),
                      ),
                      const SizedBox(height: tDashboardPadding),
                      const Text(
                        "Lab Services",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: [
                          ServiceCard(
                            icon: Icons.biotech,
                            title: 'Manage Tests',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ManageTestServicesScreen(),
                                ),
                              );
                            },
                          ),
                          ServiceCard(
                            icon: Icons.schedule,
                            title: 'Manage Booking',
                            onTap: () {},
                          ),
                          ServiceCard(
                            icon: Icons.chat,
                            title: 'Chat with Patient',
                            onTap: () {},
                          ),
                          ServiceCard(
                            icon: Icons.delivery_dining,
                            title: 'Sample Collection',
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: tDashboardPadding),
                      const Text(
                        "Lab Announcements",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: const [
                            HealthTipCard(title: "New COVID-19 Panel Test"),
                            HealthTipCard(title: "Special Discounts on Packages"),
                            HealthTipCard(title: "Extended Lab Hours"),
                            HealthTipCard(title: "Get Reports Online"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          selectedItemColor: isDark ? Colors.blue[300] : Colors.blue,
          unselectedItemColor: isDark ? Colors.white70 : Colors.black54,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard), label: "Dashboard"),
            BottomNavigationBarItem(
                icon: Icon(Icons.analytics), label: "Reports"),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today), label: "Appointments"),
            BottomNavigationBarItem(
                icon: Icon(Icons.person), label: "Profile"),
            BottomNavigationBarItem(
                icon: Icon(Icons.chat), label: "Chat"),
          ],
          onTap: (index) {},
        ),
      ),
    );
  }
}
