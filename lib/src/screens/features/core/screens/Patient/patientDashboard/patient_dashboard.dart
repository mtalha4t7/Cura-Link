import 'package:cura_link/src/notification_handler/fcmServerKey.dart';
import 'package:cura_link/src/notification_handler/notification_server.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/MyBookedNurses/my_booked_nurses_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/MyBookedNurses/my_booked_nurses_screen.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/MyBookings/my_bookings.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/NurseBooking/nurse_booking.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/NurseBooking/show_nurse_services.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/PatientChat/chat_home.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/PatientProfile/patient_profile_screen.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/health_tip_card.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/patient_dashboard_sidebar.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/quick_access_button.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/service_card.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/patientWidgets/patient_appbar.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/PatientControllers/my_bookings_controller.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/LabBooking/lab_booking.dart';

import '../../../../../../constants/sizes.dart';
import '../../../../../../mongodb/mongodb.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final MyBookingsController _myBookingController = Get.put(MyBookingsController());
  final MyBookedNursesController _myBookedNursesController = Get.put(MyBookedNursesController());
  final FirebaseAuth _auth = FirebaseAuth.instance;
  MongoDatabase mongoDatabase = MongoDatabase();
  late String _email;
  late String _userDeviceToken;
  NotificationService notificationService = NotificationService();
  GetServerKey _getServerKey = GetServerKey();

  @override
  void initState() {
    super.initState();
    _initializeAsyncStuff();
  }

  Future<void> _initializeAsyncStuff() async {
    _email = (_auth.currentUser?.email!)!;
    _userDeviceToken = await notificationService.getDeviceToken();
    await mongoDatabase.updateDeviceTokenForUser(_email, _userDeviceToken);
    notificationService.requestNotificationPermission();
    _myBookingController.fetchUnreadBookingsCount();
    _myBookedNursesController.fetchTotalReceivedBookingsCount();
    notificationService.firebaseInit(context);
    notificationService.setupInteractMessage(context);
  }

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
                Text("How can we assist you today?", style: txtTheme.displayMedium),
                const SizedBox(height: tDashboardPadding),

                // Quick Access Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    QuickAccessButton(
                      icon: Icons.medication,
                      label: 'Order Medicine',
                      onTap: () async {
                        final key = await _getServerKey.getServerTokenKey();
                        print(key);
                        print("device token= $_userDeviceToken");
                      },
                    ),
                    QuickAccessButton(
                      icon: Icons.local_hospital,
                      label: 'Call Nurse',
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        prefs.containsKey('nurseRequestId')
                            ? Get.to(() => NurseBookingScreen(selectedService: ''))
                            : Get.to(() => ShowNurseServices());
                      },
                    ),
                    QuickAccessButton(
                      icon: Icons.science,
                      label: 'Book Lab',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LabBookingScreen()),
                      ).then((_) => _myBookingController.fetchUnreadBookingsCount()),
                    ),
                  ],
                ),
                const SizedBox(height: tDashboardPadding),

                // Services Grid
                const Text(
                  "Our Services",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                Obx(() => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    ServiceCard(
                      icon: Icons.medical_services,
                      title: 'Medicine Delivery',
                      onTap: () {},
                    ),
                    ServiceCard(
                      icon: Icons.medical_services_sharp,
                      showBadge: _myBookedNursesController.totalReceivedBookingsCount.value > 0,
                      title: 'Nurse bookings',
                      onTap: () => Get.to(
                            () => MyBookedNursesScreen(
                          patientEmail: _auth.currentUser?.email ?? '',
                        ),
                      ),
                    ),
                    ServiceCard(
                      icon: Icons.biotech,
                      title: 'Lab Tests',
                      onTap: () async {
                        final key = await _getServerKey.getServerTokenKey();
                        print(key);
                        print("device token= $_userDeviceToken");
                      },
                    ),
                    ServiceCard(
                      icon: Icons.add_to_queue,
                      title: 'My Bookings',
                      showBadge: _myBookingController.unreadCount.value > 0,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyBookingsScreen()),
                      ).then((_) => _myBookingController.fetchUnreadBookingsCount()),
                    ),
                  ],
                )),

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
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey,
          selectedItemColor: isDark ? Colors.white : Colors.blue,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Orders"),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: "Messages"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                Get.offAll(() => const PatientDashboard());
                break;
              case 1:
              // Handle orders navigation
                break;
              case 2:
                Get.to(() => ChatHomeScreen());
                break;
              case 3:
                Get.to(() => PatientProfileScreen());
                break;
            }
          },
        ),
      ),
    );
  }
}