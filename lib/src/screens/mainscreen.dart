
import 'package:cura_link/src/screens/patient/patient_onboard.dart';
import 'package:flutter/material.dart';

import '../widget/widget_support.dart';
import 'lab/labOnboard.dart';
import 'medicine_store/medicine_storeOnboard.dart';
import 'nurse/nurse_onboard.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/registerbg.jpeg'), // Background image
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: <Widget>[
              // Logo at the top
              Container(
                margin: const EdgeInsets.only(top: 20), // Adjust top margin as needed
                child: Image.asset(
                  'images/appLogo.png', // Path to your logo asset
                  height: 192,
                  width: 192,
                  color: Colors.lightBlue,// Adjust the height of the logo
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top:80),
                child: const Text("Who are you?",style: TextStyle(fontFamily: 'Roboto',fontSize: 18)),
              ), // Space between logo and buttons
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // First row of buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RoleButton(
                          icon: Icons.person,
                          label: 'Patient',
                          color: AppColors.secondaryColor, // Apply secondary color
                          onPressed: () {
                            navigateToPatientOnboard(context);
                          },
                        ),
                        const SizedBox(width: 20), // Space between buttons
                        RoleButton(
                          icon: Icons.store,
                          label: 'Medical Store Owner',
                          color: AppColors.secondaryColor, // Apply secondary color
                          onPressed: () {
                            navigateToMedicineStoreOnboard(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20), // Space between rows
                    // Second row of buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RoleButton(
                          icon: Icons.medical_services,
                          label: 'Nurse',
                          color: AppColors.secondaryColor, // Apply secondary color
                          onPressed: () {
                            navigateToNurseOnboard(context);
                          },
                        ),
                        const SizedBox(width: 20), // Space between buttons
                        RoleButton(
                          icon: Icons.science,
                          label: 'Laboratory Owner',
                          color: AppColors.secondaryColor, // Apply secondary color
                          onPressed: () {
                            navigateToLabOnboard(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Navigation functions remain unchanged
void navigateToPatientOnboard(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const PatientOnboard()),
  );
}

void navigateToNurseOnboard(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const NurseOnboard()),
  );
}

void navigateToMedicineStoreOnboard(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const MedicineStoreOnboard()),
  );
}

void navigateToLabOnboard(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const LabOnboard()),
  );
}
