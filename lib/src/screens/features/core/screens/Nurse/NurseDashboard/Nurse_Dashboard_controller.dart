import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../repository/user_repository/user_repository.dart';
import '../../../models/nurse_model.dart';
import '../../../../../../mongodb/mongodb.dart'; // Make sure this gives access to `userVerification`
import 'package:mongo_dart/mongo_dart.dart';

class NurseDashboardController extends GetxController {
  final UserRepository _userRepository;
  var isLoading = false.obs;
  var isAvailable = false.obs;
  var nurse = Rx<NurseModelMongoDB?>(null);
  var isVerified = false.obs;

  NurseDashboardController(this._userRepository);

  @override
  void onInit() {
    super.onInit();
    fetchNurseData();
  }

  Future<void> fetchNurseData() async {
    try {
      isLoading(true);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null || currentUser.email == null) {
        throw Exception('No authenticated user found');
      }

      final data = await _userRepository.getNurseUserByEmail(currentUser.email!);
      if (data == null) throw Exception('Nurse profile not found for ${currentUser.email}');

      final nurseModel = NurseModelMongoDB.fromDataMap(data);
      nurse.value = nurseModel;
      isAvailable(nurseModel.isAvailable);
      isVerified(nurseModel.userVerified == "1");
    } catch (e) {
      print('Error in fetchNurseData: $e');
      Get.snackbar('Error', 'Failed to fetch nurse data: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> toggleAvailability() async {
    try {
      isLoading(true);
      final newAvailability = !isAvailable.value;
      isAvailable(newAvailability);

      final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
      await _userRepository.updateNurseUser(currentUserEmail!, {'isAvailable': newAvailability});

      nurse.value = nurse.value?.copyWith(isAvailable: newAvailability);
      Get.snackbar('Success', newAvailability ? 'You are now available' : 'You are now unavailable');
    } catch (e) {
      isAvailable(!isAvailable.value);
      Get.snackbar('Error', 'Failed to update availability: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  /// This is the method your Nurse Dashboard will call
  Future<void> verifyUser(String nic, String license, BuildContext context) async {
    await verifyNurse(nic, license, context, (success) {
      if (success) {
        isVerified(true);
      }
    });
  }

  /// --- NURSE VERIFICATION METHOD ---
  Future<void> verifyNurse(String nic, String license, BuildContext context, Function(bool) onVerified) async {
    try {
      final collection = MongoDatabase.userVerification;

      // Step 1: Check if NIC & License are valid
      final exists = await MongoDatabase.checkVerification(
        nic: nic,
        licence: license,
        collection: collection,
      );

      if (!exists) {
        Get.snackbar("Verification Failed", "NIC and License do not match any record.");
        onVerified(false);
        return;
      }

      // Step 2: Fetch document and check if already registered
      final doc = await collection?.findOne({'userNic': nic});
      if (doc == null) {
        Get.snackbar("Error", "No verification record found for NIC.");
        onVerified(false);
        return;
      }

      if (doc['assignedEmail'] != "") {
        Get.snackbar("Already Registered", "Email already registered: ${doc['assignedEmail']}");
        onVerified(false);
        return;
      }

      final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
      if (currentUserEmail == null) throw Exception("User not logged in");

      // Step 3: Update assignedEmail in verification doc
      final updatedAssignedEmail = await _updateVerificationDoc(nic, {
        'assignedEmail': currentUserEmail,
      });

      if (!updatedAssignedEmail) {
        Get.snackbar("Error", "Failed to assign email.");
        onVerified(false);
        return;
      }

      // Step 4: Update nurse's userVerified status
      final updateSuccess = await _updateNurseDoc(currentUserEmail, {
        'userVerified': "1",
      });

      if (updateSuccess) {
        Get.snackbar("Success", "Nurse verified successfully!");
        onVerified(true);
        await fetchNurseData(); // Refresh data to reflect updated status
      } else {
        Get.snackbar("Error", "Failed to update nurse verification status.");
        onVerified(false);
      }
    } catch (e) {
      print("Error verifying nurse: $e");
      Get.snackbar("Error", "An error occurred during verification.");
      onVerified(false);
    }
  }

  /// --- Helper: Update userVerification document by NIC ---
  Future<bool> _updateVerificationDoc(String nic, Map<String, dynamic> fields) async {
    try {
      final modify = ModifierBuilder();
      fields.forEach((key, value) => modify.set(key, value));

      final result = await MongoDatabase.userVerification?.updateOne({'userNic': nic}, modify);
      return result != null && result.nModified > 0;
    } catch (e) {
      print("Failed to update verification doc: $e");
      return false;
    }
  }

  /// --- Helper: Update nurse document by email ---
  Future<bool> _updateNurseDoc(String email, Map<String, dynamic> fields) async {
    try {
      final modify = ModifierBuilder();
      fields.forEach((key, value) => modify.set(key, value));

      final result = await MongoDatabase.userNurseCollection?.updateOne({'userEmail': email}, modify);
      return result != null && result.nModified > 0;
    } catch (e) {
      print("Failed to update nurse doc: $e");
      return false;
    }
  }
}
