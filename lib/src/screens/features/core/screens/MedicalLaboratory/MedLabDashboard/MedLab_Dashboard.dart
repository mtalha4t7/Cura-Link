import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/health_tip_card.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/patient_dashboard_sidebar.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/quick_access_button.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/service_card.dart';
import 'package:flutter/material.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/patient_appbar.dart';
import '../../../../../../constants/sizes.dart';

class medlab_dashboard extends StatelessWidget {
  const medlab_dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        appBar: PatientDashboardAppBar(isDark: isDark),
        drawer: PatientDashboardSidebar(isDark: isDark),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(tDashboardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome to Cura Link", style: txtTheme.bodyMedium),
                Text("How can we assist you today?",
                    style: txtTheme.displayMedium),
                const SizedBox(height: tDashboardPadding),

                // Quick Access Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    QuickAccessButton(
                      icon: Icons.medication,
                      label: 'Order Medicine',
                      onTap: () {
                        // Order Medicine action
                      },
                    ),
                    QuickAccessButton(
                      icon: Icons.local_hospital,
                      label: 'Call Nurse',
                      onTap: () {
                        // Call Nurse action
                      },
                    ),
                    QuickAccessButton(
                      icon: Icons.science,
                      label: 'Book Lab',
                      onTap: () {
                        // Book Lab Appointment action
                      },
                    ),
                  ],
                ),
                const SizedBox(height: tDashboardPadding),

                // Services Grid
                const Text(
                  "Our Services",
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
                      icon: Icons.medical_services,
                      title: 'Medicine Delivery',
                      onTap: () {
                        // Navigate to Medicine Delivery
                      },
                    ),
                    ServiceCard(
                      icon: Icons.medical_services_sharp,
                      title: 'Nurse Assistance',
                      onTap: () {
                        // Navigate to Nurse Assistance
                      },
                    ),
                    ServiceCard(
                      icon: Icons.biotech,
                      title: 'Lab Tests',
                      onTap: () {
                        // Navigate to Lab Tests
                      },
                    ),
                    ServiceCard(
                      icon: Icons.video_call,
                      title: 'Virtual Consultations',
                      onTap: () {
                        // Navigate to Virtual Consultations
                      },
                    ),
                  ],
                ),
                const SizedBox(height: tDashboardPadding),

                // Health Tips Section
                const Text(
                  "Health Tips",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      HealthTipCard(title: "Stay\nHydrated"),
                      HealthTipCard(title: "Eat Balanced Diet"),
                      HealthTipCard(title: "Regular Checkups"),
                      HealthTipCard(title: "Get Vaccinated"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart), label: "Orders"),
            BottomNavigationBarItem(
                icon: Icon(Icons.message), label: "Messages"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
          onTap: (index) {
            // Handle navigation
          },
        ),
      ),
    );
  }
}
