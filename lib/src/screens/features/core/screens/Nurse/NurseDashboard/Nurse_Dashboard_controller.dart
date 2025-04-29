// nurse_dashboard_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../repository/user_repository/user_repository.dart';
import '../../../models/nurse_model.dart';

class NurseDashboardController extends GetxController {
  final UserRepository _userRepository;
  var isLoading = false.obs;
  var isAvailable = false.obs;
  var nurse = Rx<NurseModelMongoDB?>(null);
  var isVerified = false.obs;
  var activeRequests = <Map<String, dynamic>>[].obs;

  NurseDashboardController(this._userRepository);

  @override
  void onInit() {
    super.onInit();
    fetchNurseData();
  }


  // Toggles nurse availability and updates in DB
  Future<void> toggleAvailability() async {
    try {
      isLoading(true);
      final newStatus = !isAvailable.value;
      isAvailable(newStatus);

      await _userRepository.updateNurseUser(
        nurse.value?.userEmail ?? '',
        {'isAvailable': newStatus},
      );

      Get.snackbar('Success', newStatus
          ? 'You are now available'
          : 'You are now unavailable');
    } catch (e) {
      isAvailable(!isAvailable.value); // revert change
      Get.snackbar('Error', 'Failed to update: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  // Add this method to your controller
  Future<void> fetchNurseData() async {
    try {
      isLoading(true);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser?.email == null) {
        throw Exception('No authenticated user');
      }

      final data = await _userRepository.getNurseUserByEmail(currentUser!.email!);
      nurse.value = NurseModelMongoDB.fromDataMap(data ?? {});
      isVerified(nurse.value?.userVerified == "1");
      isAvailable(nurse.value?.isAvailable ?? false);

    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch data: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

}