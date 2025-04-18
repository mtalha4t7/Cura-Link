import 'package:cura_link/src/screens/features/core/screens/Patient/PatientControllers/show_services_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../../repository/user_repository/user_repository.dart';
import '../../../../../../shared prefrences/shared_prefrence.dart';
import '../PatientControllers/lab_booking_controller.dart';

class ShowLabServices extends StatefulWidget {
  const ShowLabServices({super.key});

  @override
  _ShowLabServicesState createState() => _ShowLabServicesState();
}

class _ShowLabServicesState extends State<ShowLabServices> {
  late ShowTestServiceController _controller;
  late PatientLabBookingController _addBookingController;
  late Future<List<Map<String, dynamic>>> _services;
  late String? email; // to Make email nullable
  late String _patientName;

  @override
  void initState() {
    super.initState();
    _controller = ShowTestServiceController();
    _addBookingController = PatientLabBookingController();
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
      lastDate: DateTime.now().add(Duration(days: 365)), // One year from now
    );

    if (selectedDate == null) {
      return; // User canceled the date picker
    }

    // Select time
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime == null) {
      return; // User canceled the time picker
    }

    // Combine date and time into a DateTime object
    DateTime selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    String price = service['prize'].toString();

    // Confirm booking
    await _addBookingController.addBooking(
      _patientName, // patientName as service name
      service['serviceName'],
      price,
      selectedDateTime.toIso8601String(), // selected date and time
    );

    // Refresh the services list after booking
    setState(() {
      _services = _loadEmailAndFetchServices();
    });

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking confirmed for ${service['serviceName']}')),
    );
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