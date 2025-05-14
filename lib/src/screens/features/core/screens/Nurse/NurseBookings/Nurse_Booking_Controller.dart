import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../repository/user_repository/user_repository.dart';
import '../../../models/nurse_model.dart';


class BookingControllerNurse extends GetxController {
  final _userRepository = UserRepository();
  var isLoading = false.obs;
  var isAvailable = false.obs;
  var nurse = Rx<NurseModelMongoDB?>(null);
  var isVerified = false.obs;
  var activeRequests = <Map<String, dynamic>>[].obs;
  Timer? pollingTimer;

  @override
  void onInit() {
    super.onInit();
    fetchNurseData();
    fetchActiveRequests();
    fetchActiveRequests();
  }
  @override
  void onClose() {
    pollingTimer?.cancel();
    super.onClose();
  }
  void startPolling() {
    pollingTimer = Timer.periodic(Duration(seconds: 10), (_) {
      fetchActiveRequests(); // Call your MongoDB fetch logic
    });
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


  // Fetches service requests assigned to this nurse (or nearby in the future)
  Future<void> fetchActiveRequests() async {
    print('🔄 Starting to fetch active requests...');
    try {
      isLoading(true);
      final nurseEmail = nurse.value?.userEmail ?? '';
      print('👩⚕️ Current nurse email: $nurseEmail');

      final requests = await MongoDatabase.getNurseServiceRequests(nurseEmail);
      print('✅ Successfully fetched ${requests.length} raw requests from DB:');
      requests.forEach((req) => print('   - ${req.toString()}'));

      activeRequests.assignAll(requests);
      print('📋 Active requests list updated with ${activeRequests.length} items:');
      activeRequests.forEach((req) => print('   - ${req['_id']} (${req['status']})'));

    } catch (e, stack) {
      print('❌ Error fetching requests: ${e.toString()}');
      print('🔍 Stack trace: $stack');
      Get.snackbar('Error', 'Failed to fetch requests: ${e.toString()}');
    } finally {
      isLoading(false);
      print('🏁 Finished fetching active requests');
    }
  }

  Future<void> submitBid(String requestId, double price, String nurseName, String serviceType) async {
    try {
      isLoading(true);

      final email = nurse.value?.userEmail ?? '';
      print("==================== Nurse Name: $nurseName");

      // Check if a bid already exists for this nurse and request
      final hasAlreadyBid = await MongoDatabase.hasExistingBid(
        requestId: requestId,
        nurseEmail: email,
      );

      if (hasAlreadyBid) {
        Get.snackbar('Notice', 'You have already submitted a bid for this request.');
        return;
      }

      // Proceed with bid submission if not already submitted
      await MongoDatabase.submitBid(
        nurseName: nurseName,
        requestId: requestId,
        nurseEmail: email,
        price: price,
        serviceName: serviceType,
      );

      Get.snackbar('Success', 'Bid submitted successfully');
      await fetchActiveRequests();
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit bid: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }




  Future<Map<String, dynamic>> getNurseLocation() async {
    try {
      final nurseData = await MongoDatabase.userNurseCollection?.findOne(
          where.eq('userEmail', nurse.value?.userEmail)
      );
      return nurseData?['location'] ?? {};
    } catch (e) {
      return {};
    }
  }

  void refreshRequests() {
    fetchActiveRequests();
  }
}
