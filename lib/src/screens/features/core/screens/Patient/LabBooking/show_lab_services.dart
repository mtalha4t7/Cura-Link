import 'package:cura_link/src/notification_handler/send_notification.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/PatientControllers/show_services_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../repository/user_repository/user_repository.dart';
import '../../../../../../shared prefrences/shared_prefrence.dart';
import '../MyBookings/my_bookings.dart';
import '../PatientControllers/lab_booking_controller.dart';


class ShowLabServices extends StatefulWidget {
  const ShowLabServices({super.key});

  @override
  _ShowLabServicesState createState() => _ShowLabServicesState();
}

class _ShowLabServicesState extends State<ShowLabServices> {
  late ShowTestServiceController _controller;
  late NurseBookingController _addBookingController;
  late Future<List<Map<String, dynamic>>> _services;
  late String? email; // to Make email nullable
  late String _patientName;
  MongoDatabase mongoDatabase = MongoDatabase();
  @override
  void initState() {
    super.initState();
    _controller = ShowTestServiceController();
    _addBookingController = NurseBookingController();
    email = FirebaseAuth.instance.currentUser ?.email; // Get email from Firebase
    _services = _loadEmailAndFetchServices();
    _initializePatientName(); // Call a separate function for async operations
  }

  Future<void> _initializePatientName() async {
    if (email != null) {
      _patientName = (await UserRepository().getPatientUserName(email!)) ?? "Unknown";
      setState(() {}); // Update the state once the patient name is loaded
    }
  }


  Future<List<Map<String, dynamic>>> _loadEmailAndFetchServices() async {
    String? labUserEmail = await loadEmail();
    if (labUserEmail != null) {
      print('Using email: $labUserEmail'); // Debug print
      return _controller.fetchUserServices(labUserEmail); // Pass the email directly
    }
    return []; // Return an empty list if no email is found
  }

  Future<void> _selectDateTimeAndBook(Map<String, dynamic> service) async {
    // Select date
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (selectedDate == null) return;

    // Select time
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime == null) return;

    // Combine date and time
    DateTime selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    String price = service['prize'].toString();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      String? bookingId = await _addBookingController.addBooking(
        _patientName,
        service['serviceName'],
        price,
        selectedDateTime.toIso8601String(),
      );

      Navigator.pop(context); // Dismiss loading indicator

      if (bookingId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book. Please try again.')),
        );
        return;
      }

      // Show confirmation dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Booking Request Sent'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your booking request has been successfully sent to the lab.'),
              SizedBox(height: 16),
              Text('Test: ${service['serviceName']}'),
              Text('Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}'),
              Text('Time: ${selectedTime.format(context)}'),
              Text('Price: Rs $price'),
              SizedBox(height: 16),
              Text('Kindly check your bookings screen for status updates.',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                // Add navigation to bookings screen if needed
                 Navigator.push(context, MaterialPageRoute(builder: (context) => MyBookingsScreen()));
              },
              child: const Text('VIEW BOOKINGS', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );

      // Fetch full booking details for notification
      final bookedService = await MongoDatabase.patientBookingsCollection
          ?.findOne({'bookingId': bookingId});

      if (bookedService == null) {
        print('❌ Could not find booking with ID: $bookingId');
        return;
      }

      final labEmail = bookedService['labUserEmail'];
      final patientName = bookedService['patientName'];
      final patientEmail = bookedService['patientUserEmail'];

      print('✅ Booking found. Lab email: $patientEmail, Patient name: $patientName');

      final token = await MongoDatabase.getDeviceTokenByEmail(labEmail);

      print('📱 Device token fetched: $token');

      if (token != null) {
        final notificationSent = await SendNotificationService.sendNotificationUsingApi(
          token: token,
          title: "Lab Booked by $patientName",
          body: "Tap to check bookings",
          data: {
            "screen": "ManageBookingScreen",
          },
        );

        print('📨 Notification sending result:');
      }

    } catch (e) {
      Navigator.pop(context); // Dismiss loading indicator in case of error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lab Services'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _services,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final services = snapshot.data;

          if (services == null || services.isEmpty) {
            return Center(child: Text('No services found.'));
          }

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(service['serviceName'] ?? 'Unknown Service'),
                  subtitle: Text('Price: RS ${service['prize'] ?? 0.0}'),
                  trailing: IconButton(
                    icon: Icon(FontAwesomeIcons.cartPlus),
                    onPressed: () async {
                      final checkTestBooking= await _addBookingController.checkBookingWithSameTestName(service['serviceName']);
                      if(checkTestBooking){
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('You already Booked ${service['serviceName']} please cancel last one to proceed!')),
                        );
                      }else{
                        _selectDateTimeAndBook(service);
                      }
                      // Open calendar and time picker
                    },
                  ),
                  onTap: () {
                    // Navigate to a detail screen if needed
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}