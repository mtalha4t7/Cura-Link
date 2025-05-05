import 'package:cura_link/src/mongodb/mongodb.dart';
import 'package:cura_link/src/notification_handler/fcmServerKey.dart';
import 'package:cura_link/src/screens/features/core/screens/Nurse/MyBookings/my_bookings_screen.dart';
import 'package:cura_link/src/screens/features/core/screens/Nurse/NurseBookings/Nurse_Booking_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cura_link/src/screens/features/core/screens/Nurse/NurseProfile/Nurse_Profile_Screen.dart';
import '../../../../../../notification_handler/notification_server.dart';
import '../../Nurse/NurseWidgets/nic_input_formatter.dart';
import '../../Nurse/NurseChat/chat_home.dart';
import '../../Nurse/NurseWidgets/quick_access_button.dart';
import '../../Nurse/NurseWidgets/service_card.dart';
import '../NurseBookings/Nurse_Booking_Controller.dart';
import 'Nurse_Dashboard_controller.dart';


class NurseDashboard extends StatefulWidget {
  NurseDashboard({super.key}) {
    Get.put(NurseDashboardController());
    Get.put(BookingControllerNurse());
  }

  @override
  State<NurseDashboard> createState() => _NurseDashboardState();
}

class _NurseDashboardState extends State<NurseDashboard> {
  Future<List<Map<String, dynamic>>>? _latestBookingsFuture;
  final email = FirebaseAuth.instance.currentUser?.email;
  NotificationService notificationService = NotificationService();
  late String _userDeviceToken;
  MongoDatabase mongoDatabase = MongoDatabase();
  final GetServerKey _getServerKey = GetServerKey();
  bool isVerified = false;
  late NurseDashboardController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<NurseDashboardController>();
    _initializeAsyncStuff();
    _checkUserVerification();
  }

  Future<void> _initializeAsyncStuff() async {
    _userDeviceToken = await notificationService.getDeviceToken();
    await mongoDatabase.updateDeviceTokenForUser(email!, _userDeviceToken);
    notificationService.requestNotificationPermission();
    _latestBookingsFuture = MongoDatabase().getUpcomingBookings(email!);
    notificationService.firebaseInit(context);
    notificationService.setupInteractMessage(context);
  }

  // Dynamically check user verification status
  void _checkUserVerification() async {
    controller.checkUserVerification((status) {
      setState(() {
        isVerified = status;
      });
    });
  }

  /// Verify the user and update status
  void _verifyUser(String nic, String license) {
    controller.verifyUser(nic, license, context, (verificationSuccess) {
      if (verificationSuccess) {
        setState(() {
          isVerified = true;
        });

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

  void _showVerificationDialog() {
    final nicController = TextEditingController();
    final licenseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
                  labelStyle: const TextStyle(fontSize: 15),
                  hintText: "e.g., 15201-2808169-3",
                  hintStyle: const TextStyle(fontSize: 14),
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
                  NICInputFormatter(),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: licenseController,
                decoration: InputDecoration(
                  labelText: "License Number",
                  labelStyle: const TextStyle(fontSize: 15),
                  hintText: "Enter your license number",
                  hintStyle: const TextStyle(fontSize: 14),
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
        appBar: AppBar(
          title: Text("Nurse Dashboard", style: txtTheme.titleLarge),
          backgroundColor: isDark ? Colors.grey[900] : Colors.blue,
          actions: [
            Obx(() => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(
                    controller.isAvailable.value ? Icons.circle : Icons.circle_outlined,
                    color: controller.isAvailable.value ? Colors.green : Colors.red,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    controller.isAvailable.value ? "Available" : "Unavailable",
                    style: TextStyle(
                      color: controller.isAvailable.value ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.blue,
                ),
                child: const Text("Nurse Menu"),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('Bookings'),
                onTap: () {},
              ),
            ],
          ),
        ),
        body: Column(
          children: [
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
              child: Obx(() {
                if (controller.isLoading.value && controller.nurse.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome Back, ${controller.nurse.value?.userName ?? 'Nurse'}!",
                            style: txtTheme.bodyMedium),
                        const SizedBox(height: 16.0),

                        // Availability Toggle Button
                        Center(
                          child: GestureDetector(
                            onTap: () => controller.toggleAvailability(),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: double.infinity,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: controller.isAvailable.value
                                    ? LinearGradient(
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.green.shade700
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                    : LinearGradient(
                                  colors: [
                                    Colors.red.shade400,
                                    Colors.red.shade700
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: controller.isAvailable.value
                                        ? Colors.green.withOpacity(0.4)
                                        : Colors.red.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: controller.isLoading.value
                                        ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                        : Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          controller.isAvailable.value
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          controller.isAvailable.value
                                              ? "You're Available for Work"
                                              : "You're Not Available",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    right: 20,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      child: controller.isLoading.value
                                          ? const SizedBox()
                                          : Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          controller.isAvailable.value
                                              ? Icons.toggle_on
                                              : Icons.toggle_off,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Quick Access Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            QuickAccessButton(
                              icon: Icons.book_online,
                              label: 'Check Bookings',
                              onTap: () {
                                Get.to(() => NurseBookingsScreen());
                              },
                            ),
                            QuickAccessButton(
                              icon: Icons.medical_services,
                              label: 'Manage Bookings',
                              onTap: () {
                                Get.to(() => MyBookingsNurseScreen());
                              },
                            ),
                            QuickAccessButton(
                              icon: Icons.settings,
                              label: 'Settings',
                              onTap: () async {
                                final key = await _getServerKey.getServerTokenKey();
                                print(key);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),

                        // Bookings Section
                        const Text(
                          "Current Booking",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 200,
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: _latestBookingsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(child: Text('No current bookings found.'));
                              } else {
                                final bookings = snapshot.data!;
                                return ListView.builder(
                                  itemCount: bookings.length,
                                  itemBuilder: (context, index) {
                                    final booking = bookings[index];
                                    return ListTile(
                                      leading: const Icon(Icons.person),
                                      title: Text("Patient: ${booking['patientName'] ?? 'Unknown'}"),
                                      subtitle: Text("Date: ${booking['status']}"),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.arrow_forward),
                                        onPressed: () {
                                          Get.to(() => MyBookingsNurseScreen());
                                        },
                                      ),
                                    );
                                  },
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        // Services Section
                        const Text(
                          "Services You Provide",
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
                              icon: Icons.local_hospital,
                              title: 'Nursing Care',
                              onTap: () {},
                            ),
                            ServiceCard(
                              icon: Icons.healing,
                              title: 'Wound Care',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: "Bookings"),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                Get.to(() => NurseDashboard());
                break;
              case 1:
                break;
              case 2:
                Get.to(() => ChatHomeScreen());
                break;
              case 3:
                Get.to(() => NurseProfileScreen());
                break;
            }
          },
          backgroundColor: isDark ? Colors.grey[850] : Colors.white,
          selectedItemColor: isDark ? Colors.blueAccent : Colors.blue,
          unselectedItemColor: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }
}