import 'package:flutter/material.dart';
import '../../../../../../constants/sizes.dart';
import '../ManageLabTests/manage_test_screen.dart';
import '../MedicalLabWidgets/health_tip_card.dart';
import '../MedicalLabWidgets/medicalLab_appbar.dart';
import '../MedicalLabWidgets/medicalLab_dashboard_sidebar.dart';
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

                // Slider for Patient's Test Bookings
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
                      title: 'Manage Tests',
                      onTap: () {
                        // Navigate to Manage Tests
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
                        // Navigate to Manage Booking
                      },
                    ),
                    ServiceCard(
                      icon: Icons.chat,
                      title: 'Chat with Patient',
                      onTap: () {
                        // Navigate to Chat with Patient
                      },
                    ),
                    ServiceCard(
                      icon: Icons.delivery_dining,
                      title: 'Sample Collection',
                      onTap: () {
                        // Navigate to Sample Collection
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
          onTap: (index) {
            // Handle navigation based on the selected index
          },
        ),
      ),
    );
  }
}
