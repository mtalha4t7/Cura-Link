import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import '../../../../../../repository/user_repository/user_repository.dart';
import '../../../models/nurse_model.dart';


class NurseDashboardController extends GetxController {
  final UserRepository _userRepository;
  var isLoading = false.obs;
  var isAvailable = false.obs;
  var nurse = Rx<NurseModelMongoDB?>(null);

  NurseDashboardController(this._userRepository);

  @override
  void onInit() {
    super.onInit();
    fetchNurseData();
  }

  Future<void> fetchNurseData() async {
    try {
      isLoading(true);
      // Replace with your actual way to get current user email
      final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
      final data = await _userRepository.getNurseUserByEmail(currentUserEmail!);
      nurse.value = NurseModelMongoDB.fromDataMap(data!);
      isAvailable(nurse.value?.isAvailable ?? false);
    } catch (e) {
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

      final currentUserEmail = 'current_user@example.com';
      await _userRepository.updateNurseUser(
        currentUserEmail,
        {'isAvailable': newAvailability},
      );

      nurse.value = nurse.value?.copyWith(isAvailable: newAvailability);

      Get.snackbar(
        'Success',
        newAvailability ? 'You are now available' : 'You are now unavailable',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      isAvailable(!isAvailable.value);
      Get.snackbar(
        'Error',
        'Failed to update availability: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }
}