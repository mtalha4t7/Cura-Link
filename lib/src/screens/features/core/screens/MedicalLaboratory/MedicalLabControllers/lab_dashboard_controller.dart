import 'package:cura_link/src/mongodb/mongodb.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';

class DashboardController {
  final String? userEmail = FirebaseAuth.instance.currentUser?.email;
  bool isVerified = true;






  // Method to fetch recent bookings from bookingsCollection
  Future<List<Map<String, dynamic>>> fetchRecentBookings() async {
    try {
      // Query to filter bookings by labUserEmail
      final result = await MongoDatabase.bookingsCollection?.find({
        'labUserEmail': userEmail,  // Filter by labUserEmail
      }).toList();

      return result ?? []; // Return the result if found, otherwise return an empty list
    } catch (e) {
      print("Error fetching recent bookings: $e");
      return []; // Return an empty list in case of error
    }
  }





  // Method to check user verification status
  Future<void> checkUserVerification(Function(bool) updateVerificationStatus) async {
    try {
      // Fetch user document from the database
      final userDoc = await MongoDatabase.findUserLab(userEmail!);

      if (userDoc != null) {
        // Extract the 'userVerified' field value safely
        final String? userVerifiedString = userDoc['userVerified'] as String?;
        final bool isUserVerified = userVerifiedString == "1"; // Check if 'userVerified' is "1"

        // Log the verification status for debugging
        print("User verification status fetched: $isUserVerified");

        updateVerificationStatus(isUserVerified); // Update verification status
      } else {
        print("User not found in the database");
        updateVerificationStatus(false); // Handle case where user is not found
      }
    } catch (e) {
      print("Error fetching user verification: $e");
      updateVerificationStatus(false); // Treat the user as not verified in case of error
    }
  }


  // Method to verify the user based on NIC and License
  Future<void> verifyUser(
      String nic, String license, BuildContext context, Function(bool) onVerificationResult) async {
    try {
      // Query the userVerification collection to check if the provided NIC and License are valid
      final collection = MongoDatabase.userVerification;

      // First, check if the NIC exists and has an assignedEmail
      final existingVerification = await MongoDatabase.checkVerification(
        nic: nic,
        licence: license,
        collection: collection,
      );

      if (existingVerification) {
        // Query the document by NIC
        final userDoc = await collection?.findOne({
          'userNic': nic,
        });

        if (userDoc != null) {
          // Check if the NIC already has an assigned email
          if (userDoc['assignedEmail']!="") {
            // If the assignedEmail is already set, show a message that the user is already registered
            String assignedEmail = userDoc['assignedEmail'];

            print("User already registered with email: $assignedEmail");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("User already registered with this email: $assignedEmail")),
            );
            onVerificationResult(false); // Failed verification due to already registered email
          } else {
            // If there is no assignedEmail, set the current user's email in assignedEmail
            String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

            // Update the document to add the assignedEmail
            Map<String, dynamic> updateFields = {
              'assignedEmail': currentUserEmail,
            };

            // Perform the update
            final updateResult = await updateVerificationFields(nic, updateFields, context);
            if (updateResult) {
              // Successfully updated the assignedEmail
              Map<String, dynamic> updateVerificationStatus = {
                'userVerified': "1", // Mark as verified
              };

              // Update the verification status in the user's document
              final updateResultStatus = await updateUserFields(userEmail!, updateVerificationStatus);

              if (updateResultStatus) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User verified successfully!")),
                );
                onVerificationResult(true); // Verification successful
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to update the verification status.")),
                );
                onVerificationResult(false); // Failed to update the database
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to update assignedEmail.")),
              );
              onVerificationResult(false); // Failed to update assignedEmail
            }
          }
        } else {
          print("No document found for NIC: $nic");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No document found with the provided NIC.")),
          );
          onVerificationResult(false); // NIC not found in the database
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("NIC and License verification failed.")),
        );
        onVerificationResult(false); // NIC and License verification failed
      }
    } catch (e) {
      print("Error during user verification: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred during verification.")),
      );
      onVerificationResult(false); // In case of an error, return false
    }
  }

  // Method to update user's verification status
  Future<bool> updateUserFields(
      String email, Map<String, dynamic> fieldsToUpdate) async {
    try {
      final query = {'userEmail': email};
      final modifyBuilder = ModifierBuilder();

      // Add each field to the ModifierBuilder
      fieldsToUpdate.forEach((key, value) {
        modifyBuilder.set(key, value);
      });

      // Perform the update operation
      final result = await MongoDatabase.userLabCollection?.updateOne(
        query,
        modifyBuilder,
      );

      // Check the update result
      if (result?.nMatched == 0) {
        print('No document matched the given email.');
        return false; // No document found for the user
      } else if (result?.nModified == 0) {
        print(
            'The document was matched, but no modification was made (fields might be the same).');
        return false; // No change was made
      } else {
        print('User fields updated successfully.');
        return true; // Update successful
      }
    } catch (e) {
      print('Error updating user fields: $e');
      return false; // Error during the update process
    }
  }
}



Future<bool> updateVerificationFields(
    String nic, Map<String, dynamic> fieldsToUpdate, BuildContext context) async {
  try {
    final query = {'userNic': nic};
    final modifyBuilder = ModifierBuilder();

    // Add each field to the ModifierBuilder
    fieldsToUpdate.forEach((key, value) {
      modifyBuilder.set(key, value);
    });

    // Perform the update operation
    final result = await MongoDatabase.userVerification?.updateOne(
      query,
      modifyBuilder,
    );

    // Check the update result
    if (result?.nMatched == 0) {
      print('No document matched the given NIC.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No document found for the provided NIC.")),
      );
      return false; // No document found for the NIC
    } else if (result?.nModified == 0) {
      print('The document was matched, but no modification was made (fields might be the same).');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No updates made to the document.")),
      );
      return false; // No change was made
    } else {
      print('User fields updated successfully.');
      return true; // Update successful
    }
  } catch (e) {
    print('Error updating user fields: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Error updating user data.")),
    );
    return false; // Error during the update process
  }
}

