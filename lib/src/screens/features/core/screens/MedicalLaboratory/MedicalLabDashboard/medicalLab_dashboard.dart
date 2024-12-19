import 'package:flutter/material.dart';
import '../../../../../../constants/sizes.dart';
import '../MedicalLabWidgets/health_tip_card.dart';
import '../MedicalLabWidgets/medicalLab_appbar.dart';
import '../MedicalLabWidgets/medicalLab_dashboard_sidebar.dart';
import '../MedicalLabWidgets/quick_access_button.dart';
import '../MedicalLabWidgets/service_card.dart';

class MedicalLabDashboard extends StatelessWidget {
  const MedicalLabDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        appBar: MedicalLabDashboardAppBar(isDark: isDark),
        drawer: MedicalLabDashboardSidebar(isDark: isDark),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(tDashboardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome to Cura Link Lab", style: txtTheme.bodyMedium),
                Text("How can we assist you today?",
                    style: txtTheme.displayMedium),
                const SizedBox(height: tDashboardPadding),

                // Quick Access Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    QuickAccessButton(
                      icon: Icons.add_box,
                      label: 'Add Test',
                      onTap: () {
                        // Add Test action
                      },
                    ),
                    QuickAccessButton(
                      icon: Icons.assignment,
                      label: 'View Reports',
                      onTap: () {
                        // View Reports action
                      },
                    ),
                    QuickAccessButton(
                      icon: Icons.schedule,
                      label: 'Manage Appointments',
                      onTap: () {
                        // Manage Appointments action
                      },
                    ),
                  ],
                ),
                const SizedBox(height: tDashboardPadding),

                // Services Grid
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
                      title: 'Pathology Tests',
                      onTap: () {
                        // Navigate to Pathology Tests
                      },
                    ),
                    ServiceCard(
                      icon: Icons.science,
                      title: 'Specialized Tests',
                      onTap: () {
                        // Navigate to Specialized Tests
                      },
                    ),
                    ServiceCard(
                      icon: Icons.delivery_dining,
                      title: 'Sample Collection',
                      onTap: () {
                        // Navigate to Sample Collection
                      },
                    ),
                    ServiceCard(
                      icon: Icons.analytics,
                      title: 'Test Analytics',
                      onTap: () {
                        // Navigate to Test Analytics
                      },
                    ),
                  ],
                ),
                const SizedBox(height: tDashboardPadding),

                // Announcements Section
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
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
            BottomNavigationBarItem(
                icon: Icon(Icons.analytics), label: "Reports"),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today), label: "Appointments"),
            BottomNavigationBarItem(
                icon: Icon(Icons.person), label: "Profile"),
          ],
          onTap: (index) {
            // Handle navigation
          },
        ),
      ),
    );
  }
}
