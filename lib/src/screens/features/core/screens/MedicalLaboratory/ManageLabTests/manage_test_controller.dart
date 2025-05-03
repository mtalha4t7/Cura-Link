import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../../../mongodb/mongodb.dart';

class TestServiceController {
  // Existing fetchUserServices method remains unchanged
  Future<List<Map<String, dynamic>>> fetchUserServices() async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) {
      throw Exception("User not logged in.");
    }

    try {
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

  // Existing addTestService method remains unchanged
  Future<void> addTestService(String serviceName, double prize) async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) {
      print("Error: User not logged in.");
      return;
    }

    try {
      final existingService = await MongoDatabase.medicalLabServices?.findOne({
        'userEmail': userEmail,
        'serviceName': serviceName,
      });



      if (existingService == null) {
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

  // Existing removeTestService method remains unchanged
  Future<void> removeTestService(
      BuildContext context, String serviceName) async {
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
        await MongoDatabase.medicalLabServices?.deleteOne({
          'userEmail': userEmail,
          'serviceName': serviceName,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Test service "$serviceName" has been successfully deleted.'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
        print('Service removed successfully.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test service "$serviceName" not found.'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
        print('Service not found.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing test service: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      print('Error removing service: $e');
    }
  }

  // Updated editTestService method
  Future<void> editTestService({
    required String oldServiceName,
    required String newName,
    required double newPrize,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) {
      throw Exception("User not logged in");
    }

    try {
      // Check if new name already exists
      final existingService = await MongoDatabase.medicalLabServices?.findOne({
        'userEmail': userEmail,
        'serviceName': newName,
      });

      if (existingService != null && newName != oldServiceName) {
        throw Exception("Service name already exists");
      }

      // Perform the update
      final updateResult = await MongoDatabase.medicalLabServices?.updateOne(
        {'userEmail': userEmail, 'serviceName': oldServiceName},
        {r'$set': {'serviceName': newName, 'prize': newPrize}},
      );

      // Check if document was actually updated
      if (updateResult?.nModified == 0) {
        throw Exception("Service not found or no changes made");
      }

      print("Service updated successfully");
    } catch (e) {
      print("Error updating service: $e");
      rethrow; // Rethrow to handle in UI layer
    }
  }
}