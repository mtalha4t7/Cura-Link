import 'package:cura_link/src/screens/patient/patient_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../../widget/widget_support.dart';

class PatientMain extends StatelessWidget {
  const PatientMain({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/patientMain.jpeg'), // Background image
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: <Widget>[
              // Logo at the top
              Container(
                margin:
                    const EdgeInsets.only(top: 20), //  top margin adjustments
                child: Image.asset(
                  'images/appLogo.png',
                  height: 192,
                  width: 192,
                  color: Colors.white, //for Adjusting the height of  logo
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: AnimatedTextKit(
                  animatedTexts: [
                    ScaleAnimatedText(
                      'What would you like to do?',
                      textStyle: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      scalingFactor:
                          1.2, // Reduced scale factor for less bounce
                      duration: const Duration(
                          milliseconds: 500), // Duration for each bounce
                    ),
                  ],
                  totalRepeatCount:
                      120, // Total duration of 1 minute (120 * 0.5s = 60s)
                  pause: const Duration(
                      milliseconds: 500), // Pause between bounces
                  displayFullTextOnTap: true,
                  stopPauseOnTap: true,
                ),
              ), // Space between logo and buttons
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // First row of buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeatureButton(
                          context,
                          icon: Icons.medical_services,
                          label: 'Order Medicine',
                          onPressed: () {
                            // Navigate to  medicine ordering screen
                          },
                        ),
                        _buildFeatureButton(
                          context,
                          icon: Icons.local_hospital,
                          label: 'Book Nurse',
                          onPressed: () {
                            // Navigate to book nurse screen
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20), // Space between rows
                    // Second row of buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFeatureButton(
                          context,
                          icon: Icons.science,
                          label: 'Book Laboratory Appointment',
                          onPressed: () {
                            // Navigate to book lab appointment screen
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
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: AppColors.secondaryColor,
        style: TabStyle.react,
        items: [
          TabItem(icon: Icons.home, title: 'Home'),
          TabItem(icon: Icons.person, title: 'Profile'),
          TabItem(icon: Icons.shopping_cart, title: 'Cart'),
          TabItem(icon: Icons.account_balance_wallet, title: 'Wallet'),
        ],
        initialActiveIndex: 0, // Optional, default as 0
        onTap: (int index) {
          switch (index) {
            case 0:
              // Navigate to home screen
              break;
            case 1:
              // Navigate to profile screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
              break;
            case 2:
              // Navigate to cart details screen
              break;
            case 3:
              // Navigate to wallet screen
              break;
          }
        },
      ),
    );
  }

  Widget _buildFeatureButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onPressed}) {
    return SizedBox(
      width: 140, // Fixed width
      height: 140, // Fixed height
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.lightBlueAccent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.secondaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
