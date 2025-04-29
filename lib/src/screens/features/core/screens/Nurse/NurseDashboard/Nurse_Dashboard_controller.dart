import 'package:firebase_auth/firebase_auth.dart';
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
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null || currentUser.email == null) {
        throw Exception('No authenticated user found');
      }

      final data = await _userRepository.getNurseUserByEmail(currentUser.email!);


      if (data == null) {
        throw Exception('Nurse profile not found for ${currentUser.email}');
      }

      final nurseModel = NurseModelMongoDB.fromDataMap(data);
      if (nurseModel == null) {
        throw Exception('Failed to parse nurse data');
      }

      nurse.value = nurseModel;
      isAvailable(nurseModel.isAvailable);
    } catch (e) {
      print('Error in fetchNurseData: $e');
      Get.snackbar(
        'Error',
        'Failed to fetch nurse data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading(false);
    }
  }
  Future<void> toggleAvailability() async {
    try {
      isLoading(true);
      final newAvailability = !isAvailable.value;
      isAvailable(newAvailability);

      final currentUserEmail =FirebaseAuth.instance.currentUser?.email;
      await _userRepository.updateNurseUser(
        currentUserEmail!,
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