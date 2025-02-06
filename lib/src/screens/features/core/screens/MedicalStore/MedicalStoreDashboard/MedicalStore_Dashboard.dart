import 'package:cura_link/src/screens/features/core/screens/MedicalStore/MedicalStoreProfile/MedicalStore_Profile_Screen.dart';
import 'package:flutter/material.dart';
import '../../../../../../constants/sizes.dart';
import '../../MedicalLaboratory/MedicalLabWidgets/quick_access_button.dart';
import '../../MedicalLaboratory/MedicalLabWidgets/service_card.dart';

class MedicalStoreDashboard extends StatelessWidget {
  const MedicalStoreDashboard({super.key});

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
                onTap: () {
                  // Navigate to dashboard
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory),
                title: const Text('Inventory'),
                onTap: () {
                  // Navigate to inventory
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  // Navigate to settings
                },
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
                      icon: Icons.shopping_cart,
                      label: 'View Orders',
                      onTap: () {
                        // Navigate to orders
                      },
                    ),
                    QuickAccessButton(
                      icon: Icons.inventory,
                      label: 'Inventory',
                      onTap: () {
                        // Navigate to inventory
                      },
                    ),
                    QuickAccessButton(
                      icon: Icons.add_circle_outline,
                      label: 'Restock Items',
                      onTap: () {
                        // Navigate to restocking
                      },
                    ),
                  ],
                ),
                const SizedBox(height: tDashboardPadding),

                // Services Section
                const Text(
                  "Store Services",
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
                      icon: Icons.shopping_bag,
                      title: 'Pending Orders',
                      onTap: () {
                        // Navigate to pending orders
                      },
                    ),
                    ServiceCard(
                      icon: Icons.local_shipping,
                      title: 'Shipped Orders',
                      onTap: () {
                        // Navigate to shipped orders
                      },
                    ),
                    ServiceCard(
                      icon: Icons.reorder,
                      title: 'Restocking Requests',
                      onTap: () {
                        // Navigate to restocking requests
                      },
                    ),
                    ServiceCard(
                      icon: Icons.analytics,
                      title: 'Sales Report',
                      onTap: () {
                        // Navigate to sales reports
                      },
                    ),
                  ],
                ),
                const SizedBox(height: tDashboardPadding),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Orders"),
            BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Inventory"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
          onTap: (index) {
            if (index == 3) {
              // Navigate to Profile Screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MedicalStoreProfileScreen()),
              );
            } else if (index == 1) {
              // Navigate to Orders
            } else if (index == 2) {
              // Navigate to Inventory
            }
          },
        ),
      ),
    );
  }
}
