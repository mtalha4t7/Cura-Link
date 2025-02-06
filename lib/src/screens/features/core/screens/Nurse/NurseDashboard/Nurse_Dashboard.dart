import 'package:cura_link/src/screens/features/core/screens/Nurse/NurseProfile/Nurse_Profile_Screen.dart';
import 'package:cura_link/src/screens/features/core/screens/Nurse/NurseProfile/Nurse_Update_Profile_Screen.dart';
import 'package:flutter/material.dart';

import '../../MedicalLaboratory/MedicalLabWidgets/quick_access_button.dart';
import '../../MedicalLaboratory/MedicalLabWidgets/service_card.dart';


class NurseDashboard extends StatelessWidget {
  const NurseDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Nurse Dashboard", style: txtTheme.titleLarge),
          backgroundColor: isDark ? Colors.grey[900] : Colors.blue,
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
                onTap: () {
                  // Navigate to dashboard
                },
              ),
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('Bookings'),
                onTap: () {
                  // Navigate to bookings
                },
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome Back, Nurse!", style: txtTheme.bodyMedium),
                const SizedBox(height: 16.0),

                // Quick Access Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    QuickAccessButton(
                      icon: Icons.book_online,
                      label: 'Check Bookings',
                      onTap: () {
                        // Navigate to bookings
                      },
                    ),
                    QuickAccessButton(
                      icon: Icons.medical_services,
                      label: 'Manage Services',
                      onTap: () {
                        // Navigate to manage services
                      },
                    ),
                    QuickAccessButton(
                      icon: Icons.settings,
                      label: 'Settings',
                      onTap: () {
                        // Open settings
                      },
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
                    itemCount: 5, // Replace with dynamic data
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text("Booking #$index"),
                        subtitle: Text("Details of booking $index"),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () {
                            // Navigate to booking details
                          },
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
                      onTap: () {
                        // Navigate to Nursing Care details
                      },
                    ),
                    ServiceCard(
                      icon: Icons.healing,
                      title: 'Wound Care',
                      onTap: () {
                        // Navigate to Wound Care details
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: "Bookings"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
          onTap: (index) {
            if (index == 2) {
              // Navigate to ProfileScreen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NurseProfileScreen()),
              );
            } else {
              // Handle other navigation
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
