import 'package:cura_link/src/shared%20prefrences/shared_prefrence.dart';
import '../../../../../../mongodb/mongodb.dart';

class ShowTestServiceController {
  // Fetch user services from the new collection
  Future<List<Map<String, dynamic>>> fetchUserServices(String userEmail) async {
  print('Fetching services for user email: $userEmail'); // Debug print

  try {
  final userServices = await MongoDatabase.medicalLabServices
      ?.find({'userEmail': userEmail}).toList();

  // Print all documents in the collection for debugging
  final allDocuments = await MongoDatabase.medicalLabServices?.find().toList();
  print('All documents in medicalLabServices collection: $allDocuments');

  if (userServices != null && userServices.isNotEmpty) {
  print('User  services retrieved: $userServices');
  return userServices;
  } else {
  print('No services found for the given user email.');
  }
  } catch (e) {
  print('Error fetching user services: $e');
  }

  return [];
  }



  // Add a new service to the new collection
  Future<void> addTestService(String serviceName, double prize) async {
    final userEmail = await loadEmail();

    if (userEmail == null) {
      print("Error: User not logged in.");
      return;
    }

    try {
      // Define the lab information
      String lab =
          "Lab 101"; // Example lab info (can be dynamic as per the user's selection)

      // Check if the service already exists in the collection for the user
      final existingService = await MongoDatabase.medicalLabServices?.findOne({
        'serviceName': serviceName,
      });

      if (existingService == null) {
        // If the service doesn't exist, add it to the new collection
        await MongoDatabase.medicalLabServices?.insertOne({
          'userEmail': userEmail,
          'serviceName': serviceName,
          'prize': prize,
        });

        print('Service added successfully with prize: RS $prize');
      } else {
        print('Service already exists.');
      }
    } catch (e) {
      print('Error adding service: $e');
    }
  }

  // Remove a service from the new collection

}
