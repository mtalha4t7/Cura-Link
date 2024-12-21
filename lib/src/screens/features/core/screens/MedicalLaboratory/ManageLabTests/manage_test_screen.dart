import 'package:flutter/material.dart';
import '../../../../../../constants/sizes.dart';
import '../MedicalLabWidgets/medicalLab_appbar.dart';
import '../MedicalLabWidgets/medicalLab_dashboard_sidebar.dart';

class ManageTestServicesScreen extends StatelessWidget {
  const ManageTestServicesScreen({super.key});

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
                Text("Manage Test Services", style: txtTheme.bodyMedium),
                const SizedBox(height: tDashboardPadding),

                // Add Test Services Form
                const Text(
                  "Add Test Services",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Test Service Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: () {
                    // Add the logic to save the test service
                  },
                  child: const Text('Add Service'),
                ),
                const SizedBox(height: tDashboardPadding),

                // Example of a list of added test services
                const Text(
                  "Available Test Services",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                ListView(
                  shrinkWrap: true,
                  children: const [
                    ListTile(
                      title: Text("Blood Test"),
                      trailing: Icon(Icons.edit),
                    ),
                    ListTile(
                      title: Text("COVID-19 Test"),
                      trailing: Icon(Icons.edit),
                    ),
                    ListTile(
                      title: Text("X-Ray"),
                      trailing: Icon(Icons.edit),
                    ),
                    ListTile(
                      title: Text("MRI"),
                      trailing: Icon(Icons.edit),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
