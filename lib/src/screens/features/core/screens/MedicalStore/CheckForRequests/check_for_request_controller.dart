import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../repository/user_repository/user_repository.dart';
import '../../../models/medical_store_user_medel.dart';


class CheckForRequestsController extends GetxController {
  final _userRepository = UserRepository();
  var isLoading = false.obs;
  var isAvailable = false.obs;
  var medicalStore = Rx<MedicalStoreModelMongoDB?>(null);
  var isVerified = false.obs;
  var activeRequests = <Map<String, dynamic>>[].obs;
  Timer? pollingTimer;

  @override
  void onInit() {
    super.onInit();
    fetchMedicalStoreData();
    fetchActiveRequests();
    startPolling();
  }

  @override
  void onClose() {
    pollingTimer?.cancel();
    super.onClose();
  }

  void startPolling() {
    pollingTimer = Timer.periodic(Duration(seconds: 10), (_) {
      fetchActiveRequests();
    });
  }

  Future<void> fetchMedicalStoreData() async {
    try {
      isLoading(true);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser?.email == null) {
        throw Exception('No authenticated user');
      }

      final data = await _userRepository.getMedicalStoreUserByEmail(currentUser!.email!);
      medicalStore.value = MedicalStoreModelMongoDB.fromDataMap(data ?? {});
      isVerified(medicalStore.value?.userVerified == "1");
      isAvailable(medicalStore.value?.isAvailable ?? false);

    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch data: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchActiveRequests() async {
    print('🔄 Starting to fetch active requests...');
    try {
      isLoading(true);
      final storeEmail = medicalStore.value?.userEmail ?? '';
      print('🏥 Current medical store email: $storeEmail');

      final requests = await MongoDatabase.getStoreServiceRequests(storeEmail);
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

  Future<void> submitBid(
      String requestId,
      double price,
      String storeName, {
        String? prescriptionDetails,
        List<dynamic>? medicines,
        double? totalPrice,
        String? prescriptionImage,
      }) async {
    try {
      isLoading(true);
      print("====================" + storeName);

      final email = await FirebaseAuth.instance.currentUser?.email;
      final storeLocation= await MongoDatabase.getUserLocationByEmail(email!);

      // Prepare bid data
      final bidData = {
        'storeName': storeName,
        'storeEmail': medicalStore.value?.userEmail ?? '',
        'price': price,
        'submittedAt': DateTime.now(),
        if (prescriptionDetails != null)
          'prescriptionDetails': prescriptionDetails,
        if (medicines != null)
          'medicines': medicines,
        if (totalPrice != null)
          'totalPrice': totalPrice,
        if (prescriptionImage != null)
          'prescriptionImage': prescriptionImage,
          'storeLocation': storeLocation,
      };

      await MongoDatabase.submitStoreBid(
        requestId: requestId,
        bidData: bidData,
      );

      Get.snackbar(
        'Success',
        prescriptionDetails != null
            ? 'Prescription bid submitted successfully'
            : 'Bid submitted successfully',
      );

      await fetchActiveRequests();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit bid: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<Map<String, dynamic>> getStoreLocation() async {
    try {
      final storeData = await MongoDatabase.userMedicalStoreCollection?.findOne(
          where.eq('userEmail', medicalStore.value?.userEmail)
      );
      return storeData?['location'] ?? {};
    } catch (e) {
      return {};
    }
  }

  void refreshRequests() {
    fetchActiveRequests();
  }
}