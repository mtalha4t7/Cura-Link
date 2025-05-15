import 'package:cura_link/src/repository/authentication_repository/authentication_repository.dart';
import 'package:cura_link/src/screens/features/core/screens/MedicalStore/CheckForRequests/check_for_requests.dart';
import 'package:cura_link/src/screens/features/core/screens/MedicalStore/MedicalStoreProfile/MedicalStore_Profile_Screen.dart';
import 'package:cura_link/src/screens/features/core/screens/MedicalStore/MyPendingAndCompletedOrders/completed_orders_screen.dart';
import 'package:cura_link/src/screens/features/core/screens/MedicalStore/MyPendingAndCompletedOrders/pending_orders_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../constants/sizes.dart';
import '../../MedicalStore/MedicalStoreChat/chat_home.dart';
import '../../MedicalLaboratory/MedicalLabWidgets/quick_access_button.dart';
import '../../MedicalLaboratory/MedicalLabWidgets/service_card.dart';
import 'medical_store_dashboard_controller.dart';

class MedicalStoreDashboard extends StatefulWidget {
  MedicalStoreDashboard({super.key}) {
    Get.put(MedicalStoreDashboardController());
  }

  @override
  State<MedicalStoreDashboard> createState() => _MedicalStoreDashboardState();
}

class _MedicalStoreDashboardState extends State<MedicalStoreDashboard> {
  final MedicalStoreDashboardController controller = Get.find();
  bool isVerified = false;
  bool isBlocked = false;
  bool isCheckingBlockStatus = true;
  final storeEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  void initState() {
    super.initState();
    _checkUserVerification();

    // Check block status
    controller.checkUserBlockedStatus((status) {
      if (mounted) {
        setState(() {
          isBlocked = status;
          isCheckingBlockStatus = false; // Finished checking
        });

        // Only check verification if not blocked
        if (!status) {
          _checkUserVerification();
        }
      }
    });
  }

  void _checkUserVerification() async {
    controller.checkUserVerification((status) {
      if (mounted) {
        setState(() {
          isVerified = status;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    if (isCheckingBlockStatus) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (isBlocked) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                Text(
                  "Access Denied",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Your account has been blocked.\nPlease contact support(usaamaajaved@gmail.com) for further assistance.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () async {
                    await AuthenticationRepository.instance.logout();
                    // Replace with your login route
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }


    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Medical Store Dashboard", style: txtTheme.titleLarge),
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
        body: Column(
          children: [
            if (!isVerified)
              GestureDetector(
                onTap: () => _showVerificationDialog(),
                child: Container(
                  color: Colors.redAccent,
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  child: const Text(
                    "Your store is not verified. Tap here to verify.",
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
                      Text("Welcome Back!", style: txtTheme.bodyMedium),
                      Text("Manage your store effectively.", style: txtTheme.displayMedium),
                      const SizedBox(height: tDashboardPadding),

                      Obx(() => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => controller.toggleAvailability(),
                          child: Stack(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
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
                                ),
                              ),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (controller.isLoading.value)
                                        const CircularProgressIndicator(color: Colors.white)
                                      else
                                        Icon(
                                          controller.isAvailable.value
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      const SizedBox(width: 15),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            controller.isAvailable.value
                                                ? "STORE OPEN"
                                                : "STORE CLOSED",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            controller.isAvailable.value
                                                ? "Accepting orders now"
                                                : "Not accepting orders",
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 20,
                                top: 0,
                                bottom: 0,
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
                      )),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          QuickAccessButton(
                              icon: Icons.medical_services_rounded,
                              label: 'View Order Requests',
                              onTap: () async {
                                final userEmail = FirebaseAuth.instance.currentUser?.email;

                                if (userEmail == null) {
                                  Get.snackbar('Error', 'User not logged in');
                                  return;
                                }
                                try {
                                  final isVerified = controller.isVerified;

                                  if (isVerified == true) {
                                    Get.to(() => CheckForRequestsScreen());
                                  } else {
                                    Get.snackbar('Access Denied', 'Your account is not verified yet');
                                  }
                                } catch (e) {
                                  print('[onTap] Error checking verification status: $e');
                                  Get.snackbar('Error', 'Failed to verify user');
                                }
                              }
                          ),
                          QuickAccessButton(
                            icon: Icons.star,
                            label: 'Ratings',
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: tDashboardPadding),
                      const Text(
                        "Medical Store Services",
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
                            icon: Icons.pending_actions,
                            title: 'Pending Orders',
                            onTap: () {
                              Get.to(() => PendingOrdersScreen(storeEmail: storeEmail!));
                            },
                          ),
                          ServiceCard(
                            icon: Icons.local_shipping,
                            title: 'Completed Orders',
                            onTap: () {
                              Get.to(() => CompletedOrdersScreen(storeEmail: storeEmail!));
                            },
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
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
          onTap: (index) {
            switch (index) {
              case 0: Get.to(() => MedicalStoreDashboard()); break;
              case 1: Get.to(() => ChatHomeScreen()); break;
              case 2: Get.to(() => MedicalStoreProfileScreen()); break;
            }
          },
        ),
      ),
    );
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
          "Verify Your Store",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nicController,
                decoration: InputDecoration(
                  labelText: "Owner NIC",
                  hintText: "Enter owner's NIC number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: licenseController,
                decoration: InputDecoration(
                  labelText: "Store License",
                  hintText: "Enter store license number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final nic = nicController.text.trim();
              final license = licenseController.text.trim();
              Navigator.of(context).pop();
              _verifyStore(nic, license);
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  void _verifyStore(String nic, String license) {
    controller.verifyStore(nic, license, context, (verificationSuccess) {
      if (verificationSuccess) {
        setState(() {
          isVerified = true;
        });
        Get.snackbar("Success", "Store verified successfully!");
      } else {
        Get.snackbar("Error", "Verification failed. Please check your details.");
      }
    });
  }
}