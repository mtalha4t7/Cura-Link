import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cura_link/src/screens/features/core/screens/Nurse/NurseProfile/Nurse_Profile_Screen.dart';
import '../../../../../../repository/user_repository/user_repository.dart';
import '../../Nurse/NurseChat/chat_home.dart';
import '../../MedicalLaboratory/MedicalLabWidgets/quick_access_button.dart';
import '../../MedicalLaboratory/MedicalLabWidgets/service_card.dart';
import 'Nurse_Dashboard_controller.dart';


class NurseDashboard extends StatelessWidget {
  NurseDashboard({super.key}) {
    Get.put(NurseDashboardController(Get.find<UserRepository>()));
  }

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final controller = Get.find<NurseDashboardController>();

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
        body: Obx(() {
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
                      onTap: controller.toggleAvailability,
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
                        onTap: () {},
                      ),
                      QuickAccessButton(
                        icon: Icons.medical_services,
                        label: 'Manage Services',
                        onTap: () {},
                      ),
                      QuickAccessButton(
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Bookings Section
                  const Text(
                    "Current Bookings",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text("Booking #$index"),
                          subtitle: Text("Details of booking $index"),
                          trailing: IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () {},
                          ),
                        );
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
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: "Bookings"),
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