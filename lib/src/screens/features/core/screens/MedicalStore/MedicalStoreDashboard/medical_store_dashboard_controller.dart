import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../repository/user_repository/user_repository.dart';
import '../../../models/medical_store_user_medel.dart';

class MedicalStoreDashboardController extends GetxController {
  var isLoading = false.obs;
  var isAvailable = false.obs;
  var isVerified = false.obs;
  final String? userEmail = FirebaseAuth.instance.currentUser?.email;
  var store = Rx<MedicalStoreModelMongoDB?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchMedicalStoreData();
  }

  Future<void> checkUserBlockedStatus(Function(bool) onBlockedStatusChecked) async {
    try {
      // Fetch user document from the database
      final userDoc = await MongoDatabase.findUserMedicalStore(userEmail!);

      if (userDoc != null) {
        // Check if the user status is set to 'blocked'
        final String? userStatus = userDoc['status'] as String?;
        final bool isBlocked = userStatus?.toLowerCase() == 'blocked';

        // Debug log
        print("User block status fetched: $isBlocked");

        onBlockedStatusChecked(isBlocked); // Pass true if blocked
      } else {
        print("User not found in the database");
        onBlockedStatusChecked(false); // Default to not blocked if not found
      }
    } catch (e) {
      print("Error fetching user block status: $e");
      onBlockedStatusChecked(false); // Fail-safe: allow access if error occurs
    }
  }


  Future<void> fetchMedicalStoreData() async {
    try {
      isLoading(true);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser?.email == null) {
        throw Exception('No authenticated user');
      }

      final data = await UserRepository.instance.getMedicalStoreUserByEmail(currentUser!.email!);
      if (data != null) {
        store.value = MedicalStoreModelMongoDB.fromDataMap(data);
        isVerified(store.value?.userVerified == "1");
        isAvailable(store.value?.isAvailable ?? false);
      } else {
        throw Exception('No nurse data found for this user');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch data: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> toggleAvailability() async {
    try {
      isLoading(true);
      final newStatus = !isAvailable.value;
      isAvailable(newStatus);
      await UserRepository.instance.updateMedicalStoreUser(
        userEmail ?? '',
        {'isAvailable': newStatus},
      );

      Get.snackbar('Success', newStatus
          ? 'Store is now available for orders'
          : 'Store is now unavailable');
    } catch (e) {
      isAvailable(!isAvailable.value); // revert change
      Get.snackbar('Error', 'Failed to update: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> checkUserVerification(Function(bool) updateVerificationStatus) async {
    try {
      final userDoc = await MongoDatabase.findUserMedicalStore(userEmail!);
      if (userDoc != null) {
        final String? userVerifiedString = userDoc['userVerified'] as String?;
        final bool isUserVerified = userVerifiedString == "1";
        updateVerificationStatus(isUserVerified);
      } else {
        updateVerificationStatus(false);
      }
    } catch (e) {
      updateVerificationStatus(false);
    }
  }

  Future<void> verifyStore(
      String nic, String license, BuildContext context, Function(bool) onVerificationResult) async {
    try {
      final collection = MongoDatabase.userVerification;
      final existingVerification = await MongoDatabase.checkVerification(
        nic: nic,
        licence: license,
        collection: collection,
      );

      if (existingVerification) {
        final userDoc = await collection?.findOne({'userNic': nic});
        if (userDoc != null) {
          if (userDoc['assignedEmail'] != "") {
            Get.snackbar("Error", "This license is already registered");
            onVerificationResult(false);
          } else {
            final updateResult = await updateVerificationFields(nic, {
              'assignedEmail': userEmail,
            }, context);

            if (updateResult) {
              final updateResultStatus = await updateUserFields(userEmail!, {
                'userVerified': "1",
              });
              onVerificationResult(updateResultStatus);
            } else {
              onVerificationResult(false);
            }
          }
        } else {
          onVerificationResult(false);
        }
      } else {
        onVerificationResult(false);
      }
    } catch (e) {
      onVerificationResult(false);
    }
  }


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
      final result = await MongoDatabase.userMedicalStoreCollection?.updateOne(
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

}