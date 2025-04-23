import 'package:bson/bson.dart';
import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/LabBooking/temp_userModel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../shared prefrences/shared_prefrence.dart';
import '../../../../../../utils/helper/helper_controller.dart';
import '../../../../authentication/models/user_model.dart';

class PatientLabBookingController {
  // Fetch user bookings from the MongoDB collection
  final _userRepo = UserRepository();





  // Add a new booking to the MongoDB collection
  Future<void> addBooking(String patientName,
      String testName,
      String price,
      String bookingDate,) async {
    final user = FirebaseAuth.instance.currentUser;
    final patientUserEmail = user?.email;

    final userEmail = await loadEmail();
    final userName = await loadName();


    if (userEmail == null) {
      print("Error: User not logged in.");
      return;
    }

    try {
      // Check if a similar booking already exists in the main bookings collection
      final existingBooking = await MongoDatabase.bookingsCollection?.findOne({
        'userEmail': userEmail,
        'patientName': patientName,
        'testName': testName,
        'bookingDate': bookingDate,
      });

      if (existingBooking == null) {
        // Insert the booking into the main bookings collection with the price
        final result = await MongoDatabase.bookingsCollection?.insertOne({
          'labUserEmail': userEmail,
          'labUserName' : userName,
          'patientUserEmail': patientUserEmail,
          'patientName': patientName,
          'testName': testName,
          'bookingDate': bookingDate,
          'price': price, // Store price in the booking
          'status': 'Pending', // Initialize with a default status
        });
        if (result != null && result.isSuccess) {
          // Access the generated _id from the result's 'document' field
          final bookingId = result.document?['_id']?.toHexString();

          if (bookingId != null) {
            // Insert the booking into the patient bookings collection with the bookingId
            await MongoDatabase.patientBookingsCollection?.insertOne({
              'bookingId': bookingId,
              // Use the generated _id from bookingsCollection as bookingId
              'patientUserEmail': patientUserEmail,
              'labUserName' : userName,
              'patientName': patientName,
              'testName': testName,
              'bookingDate': bookingDate,
              'price': price,
              // Store price in the patient booking
              'status': 'Pending',
              // Initialize with a default status
            });

            print(
                'Booking added successfully to bookingsCollection and patientBookingsCollection.');
          } else {
            print('Error: Generated bookingId is null.');
          }
        } else {
          print('Error inserting booking into bookingsCollection.');
        }
      } else {
        print('Booking already exists.');
      }
    } catch (e) {
      print('Error adding booking: $e');
    }
  }

  // Remove a booking from the MongoDB collection
  Future<void> removeBooking(String patientName) async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) {
      print("Error: User not logged in.");
      return;
    }

    try {
      // Query the booking by patient name and user email
      final userBooking = await MongoDatabase.bookingsCollection?.findOne({
        'userEmail': userEmail,
        'patientName': patientName,
      });

      if (userBooking != null) {
        // Delete the booking if found
        await MongoDatabase.bookingsCollection?.deleteOne({
          'userEmail': userEmail,
          'patientName': patientName,
        });

        print('Booking removed successfully.');
      } else {
        print('No matching booking found.');
      }
    } catch (e) {
      print('Error removing booking: $e');
    }
  }

  // Update the status of a booking
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      // Update the status field for the specified booking
      await MongoDatabase.bookingsCollection?.updateOne(
        {'_id': bookingId}, // Filter by booking ID
        {'\$set': {'status': newStatus}}, // Update the status
      );

      print('Booking status updated to: $newStatus');
    } catch (e) {
      print('Error updating booking status: $e');
    }
  }

  // Fetch all users from the MongoDB collection
  Future<List<ShowLabUserModel>> fetchAllUsers() async {
    try {
      debugPrint("Fetching users from lab collection...");
      final userCollection = await _userRepo.getAllUsers(MongoDatabase.userLabCollection);
      debugPrint("Received ${userCollection.length} raw user records");

      final List<ShowLabUserModel> allUsers = userCollection
          .where((user) =>
      user != null &&
          user['userVerified'] == '1' &&
          user['userAddress'] != null &&
          user['userName'] != null
      )
          .map((user) {
        try {
          // Convert ObjectId to String if needed
          final modifiedUser = Map<String, dynamic>.from(user);
          if (modifiedUser['_id'] != null && modifiedUser['_id'] is ObjectId) {
            modifiedUser['_id'] = modifiedUser['_id'].toString();
          }
          return ShowLabUserModel.fromJson(modifiedUser);
        } catch (e) {
          debugPrint("Error parsing user: $e");
          return null;
        }
      })
          .whereType<ShowLabUserModel>()
          .toList();

      debugPrint("Returning ${allUsers.length} verified labs");
      return allUsers;
    } catch (e) {
      debugPrint("Error in fetchAllUsers: $e");
      rethrow;
    }
  }


  Future<List<UserModel>> getAllUsers() async {
    try {
      // Fetching all users from the collection (could be combined if using a single collection).
      final labCollection =
      await _userRepo.getAllUsers(MongoDatabase.userLabCollection);

      // Combine all user lists into one collection.
      List<UserModel> allUsers = [
        ...labCollection.map((user) => UserModel.fromJson(user)),
      ];
      return allUsers; // Return the combined list of users.
    } catch (e) {
      Helper.errorSnackBar(title: 'Error', message: e.toString());
      return [];
    }
  }


  // Update the booking date
  Future<void> updateBookingDate(String bookingId, String newDate) async {
    try {
      // Update the bookingDate field for the specified booking
      await MongoDatabase.bookingsCollection?.updateOne(
        {'_id': bookingId}, // Filter by booking ID
        {'\$set': {'bookingDate': newDate}}, // Update the booking date
      );

      print('Booking date updated to: $newDate');
    } catch (e) {
      print('Error updating booking date: $e');
    }
  }
  Future<bool> checkBookingWithSameTestName(String testName) async {
    try {
      final email = FirebaseAuth.instance.currentUser ?.email;

      if (email == null) {
        print('User  is not logged in.');
        return false; // User is not logged in, return false
      }

      print('Checking for bookings with email: $email and test name: $testName'); // Debug print

      // Print all bookings for the user for debugging
      final allBookings = await MongoDatabase.patientBookingsCollection?.find({'patientUserEmail': email}).toList();
      print('All bookings for user: $allBookings');

      // Print all bookings in the collection for debugging
      final allBookingsInCollection = await MongoDatabase.patientBookingsCollection?.find().toList();
      print('All bookings in the collection: $allBookingsInCollection');

      // Query the bookings collection to check for existing bookings
      final existingBooking = await MongoDatabase.patientBookingsCollection?.findOne({
        'patientUserEmail': email.trim(), // Use the correct field name
        'testName': testName.trim() // Trim whitespace
      });

      if (existingBooking != null) {
        print('User  already has a booking for the test: $testName');
        return true; // Booking exists
      } else {
        print('No existing booking found for the test: $testName');
        return false; // No booking exists
      }
    } catch (e) {
      print('Error checking for existing booking: $e');
      return false; // Return false in case of an error
    }
  }
}

