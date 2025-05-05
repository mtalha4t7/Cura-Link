
import 'package:cura_link/src/screens/features/core/screens/MedicalStore/MedicalStoreProfile/MedicalStore_Profile_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../constants/sizes.dart';
import '../../MedicalStore/MedicalStoreChat/chat_home.dart';
import '../../MedicalLaboratory/MedicalLabWidgets/quick_access_button.dart';
import '../../MedicalLaboratory/MedicalLabWidgets/service_card.dart';
import 'medical_store_dashboard_controller.dart';

class MedicalStoreDashboard extends StatelessWidget {
  MedicalStoreDashboard({super.key});

  final MedicalStoreDashboardController controller =
  Get.put(MedicalStoreDashboardController());

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Medical Store Dashboard", style: txtTheme.titleLarge),
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
                child: const Text("Medical Store Menu"),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text('Customer Support'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {},
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(tDashboardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome Back!", style: txtTheme.bodyMedium),
                Text("Manage your store effectively.", style: txtTheme.displayMedium),
                const SizedBox(height: tDashboardPadding),

                // Quick Access Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    QuickAccessButton(
                      icon: Icons.medical_services_rounded,
                      label: 'View Order Requests',
                      onTap: () {
                        // Navigate to orders
                      },
                    ),
                    QuickAccessButton(
                      icon: Icons.star,
                      label: 'Ratings',
                      onTap: () {
                        // Navigate to inventory
                      },
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
                      onTap: () {},
                    ),
                    ServiceCard(
                      icon: Icons.local_shipping,
                      title: 'Completed Orders',
                      onTap: () {},
                    ),



                  ],
                ),
                const SizedBox(height: tDashboardPadding),
              ],
            ),
          ),
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
              case 0:
                Get.to(() => MedicalStoreDashboard());
                break;
              case 1:
                Get.to(() => ChatHomeScreen());
                break;
              case 2:
                Get.to(MedicalStoreProfileScreen()) ;
                break;
              
            }
          },
        ),

      ),
    );
  }
}
