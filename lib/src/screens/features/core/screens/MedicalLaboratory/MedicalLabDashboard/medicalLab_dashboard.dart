import 'package:cura_link/src/mongodb/mongodb.dart';
import 'package:cura_link/src/screens/features/core/screens/MedicalLaboratory/MedicalLabProfile/medicalLab_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../../../notification_handler/notification_server.dart';
import '../../MedicalLaboratory/MedicalLabChat/chat_home.dart';
import '../ManageBooking/ManageBooking.dart';
import '../ManageLabTests/manage_test_screen.dart';
import '../MedicalLabControllers/lab_dashboard_controller.dart';
import '../MedicalLabWidgets/health_tip_card.dart';
import '../MedicalLabWidgets/medicalLab_appbar.dart';
import '../MedicalLabWidgets/medicalLab_dashboard_sidebar.dart';
import '../MedicalLabWidgets/nic_input_formatter.dart';
import '../MedicalLabWidgets/service_card.dart';

class MedicalLabDashboard extends StatefulWidget {
  const MedicalLabDashboard({super.key});

  @override
  _MedicalLabDashboardState createState() => _MedicalLabDashboardState();
}
class _MedicalLabDashboardState extends State<MedicalLabDashboard> {
  late DashboardController _controller;
  bool isVerified = false;
NotificationService notificationService = NotificationService();
MongoDatabase mongoDatabase= MongoDatabase();

  String? _userDeviceToken;
  late String _mail;



  @override
  void initState() {
    super.initState();
    _controller = DashboardController();

    _mail= (FirebaseAuth.instance.currentUser?.email)!;
    _initializeDeviceToken();
    notificationService.requestNotificationPermission();
    notificationService.firebaseInit(context);
    notificationService.setupInteractMessage(context);
    _checkUserVerification();
  }


  Future<void> _initializeDeviceToken() async {
    _userDeviceToken = await notificationService.getDeviceToken();
    await mongoDatabase.updateDeviceTokenForUser(_mail, _userDeviceToken!);
  }




  /// Dynamically check user verification status
  void _checkUserVerification() async {
    _controller.checkUserVerification((status) {
      setState(() {
        isVerified = status;
      });
    });
  }

  /// Verify the user and update status
  void _verifyUser(String nic, String license) {
    _controller.verifyUser(nic, license, context, (verificationSuccess) {
      if (verificationSuccess) {
        setState(() {
          isVerified = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User verified successfully!")),
        );
      } else {
        // Add additional checks for different failure reasons
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("NIC and License verification failed.")),
        );
      }
    });
  }


  /// Show verification dialog
  void _showVerificationDialog() {
    final nicController = TextEditingController();
    final licenseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded corners
        ),
        title: const Text(
          "Verify Your Account",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nicController,
                decoration: InputDecoration(
                  labelText: "ID Card (NIC)",
                  labelStyle: TextStyle(fontSize: 15),
                  hintText: "e.g., 15201-2808169-3",
                  hintStyle: TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  NICInputFormatter(), // Custom formatter retained
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: licenseController,
                decoration: InputDecoration(
                  labelText: "License Number",
                  labelStyle: TextStyle(fontSize: 15),
                  hintText: "Enter your license number",
                  hintStyle: TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                maxLength: 10,

              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final nic = nicController.text.trim();
              final license = licenseController.text.trim();
              String cleanNic = nic.replaceAll('-', '');
              Navigator.of(context).pop();
              _verifyUser(cleanNic, license);
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
            // Verification alert
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Welcome to Cura Link Lab", style: txtTheme.bodyMedium),
                      Text("How can we assist you today?", style: txtTheme.displayMedium),
                      const SizedBox(height: 16),
                      const Text(
                        "Recent Bookings",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 120,
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: _controller.fetchRecentBookings(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              final bookings = snapshot.data!;
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: bookings.length,
                                itemBuilder: (context, index) {
                                  final booking = bookings[index];
                                  final title =
                                      '${booking['patientName']} - ${booking['testName']} - ${booking['bookingDate']}';
                                  return HealthTipCard(title: title);
                                },
                              );
                            } else {
                              return const Center(child: Text('No recent bookings.'));
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                  builder: (context) => const ManageTestServicesScreen(),
                                ),
                              );
                            },
                          ),
                          ServiceCard(
                            icon: Icons.schedule,
                            title: 'Manage Booking',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ManageBookingScreen(),
                                ),
                              );
                            },
                          ),
                          ServiceCard(
                            icon: Icons.chat,
                            title: 'Chat with Patient',
                            onTap: () async {
                            Get.to(ChatHomeScreen());
                            },
                          ),
                          ServiceCard(
                            icon: Icons.delivery_dining,
                            title: 'Sample Collection',
                            onTap: () {},
                          ),
                        ],
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
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Appointments"),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),

          ],
          onTap: (index) {
            switch (index) {
              case 0:
                Get.to(() => MedicalLabDashboard());
                break;
              case 1:
                break;
              case 2:
                Get.to(() => ChatHomeScreen());
                break;
              case 3:
                Get.to(() => MedicalLabProfileScreen());
                break;
            }
          },
        ),
      ),
    );
  }
}
