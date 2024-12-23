import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../../mongodb/mongodb.dart';

class TestServiceController {
  // Fetch user services from the new collection
  Future<List<Map<String, dynamic>>> fetchUserServices() async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) {
      throw Exception("User not logged in.");
    }

    try {
      // Fetch services from the new collection based on user's email
      final userServices = await MongoDatabase.medicalLabServices
          ?.find({'userEmail': userEmail}).toList();
      if (userServices != null) {
        return userServices;
      }
    } catch (e) {
      print('Error fetching user services: $e');
    }

    return [];
  }

  // Add a new service to the new collection
  Future<void> addTestService(String serviceName, double prize) async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

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
  Future<void> removeTestService(String serviceName) async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) {
      print("Error: User not logged in.");
      return;
    }

    try {
      final userService = await MongoDatabase.medicalLabServices?.findOne({
        'userEmail': userEmail,
        'serviceName': serviceName,
      });

      if (userService != null) {
        // Remove the service from the new collection
        await MongoDatabase.medicalLabServices?.deleteOne({
          'userEmail': userEmail,
          'serviceName': serviceName,
        });

        print('Service removed successfully.');
      }
    } catch (e) {
      print('Error removing service: $e');
    }
  }
}
