import 'package:cura_link/src/mongodb/mongodb.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mongo_dart/mongo_dart.dart';

class DashboardController {
  final String? userEmail = FirebaseAuth.instance.currentUser?.email;
  bool isVerified = true;

  // Method to check user verification status
  Future<void> checkUserVerification(
      Function(bool) updateVerificationStatus) async {
    try {
      // Fetch user document from the database
      final userDoc = await MongoDatabase.findUserLab(userEmail!);

      if (userDoc != null) {
        // Extract the 'userVerified' field value
        final String userVerifiedString =
            userDoc['userVerified'] ?? "0"; // Default to "0" if not found
        final bool isUserVerified =
            userVerifiedString == "1"; // Check if 'userVerified' is "1"

        updateVerificationStatus(isUserVerified); // Update verification status
      } else {
        print("User not found in the database");
        updateVerificationStatus(
            false); // Ensure we handle the case where user is not found
      }
    } catch (e) {
      print("Error fetching user verification: $e");
      updateVerificationStatus(
          false); // In case of an error, we treat the user as not verified
    }
  }

  // Method to verify the user based on NIC and License
  Future<void> verifyUser(
      String nic, String license, Function(bool) onVerificationResult) async {
    try {
      // Query the userVerification collection to check if the provided NIC and License are valid
      final collection = MongoDatabase.userVerification;
      bool verification = await MongoDatabase.checkVerification(
        nic: nic,
        licence: license,
        collection: collection,
      );

      if (verification) {
        // If verification is successful, update the user's verification status
        Map<String, dynamic> updateFields = {
          'userVerified': "1", // Mark as verified
        };

        // Update the verification status in the user's document
        final updateResult = await updateUserFields(userEmail!, updateFields);

        if (updateResult) {
          onVerificationResult(true); // Verification successful
        } else {
          onVerificationResult(false); // Failed to update the database
        }
      } else {
        onVerificationResult(false); // NIC and License verification failed
      }
    } catch (e) {
      print("Error during user verification: $e");
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
