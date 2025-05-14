import 'dart:async';
import 'dart:math';

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
  var _nurseLocation;


  @override
  void onInit() {
    super.onInit();
    fetchNurseData();
    startPolling();
  }
  @override
  void onClose() {
    pollingTimer?.cancel();
    super.onClose();
  }
  void startPolling() {
    fetchActiveRequests();
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
      final email=currentUser?.email;
      _nurseLocation = await MongoDatabase.getUserLocationByEmail(email!);

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
  Future<double> calculateDistanceBetweenLocations(Map<String, dynamic> patientLocation) async {
    try {
      if (_nurseLocation == null || patientLocation.isEmpty) return 0.0;

      final patientCoords = extractCoordinates(patientLocation);
      print('storeee $_nurseLocation');
      print('patient $patientLocation');
      final storeCoords = extractCoordinates(_nurseLocation!);

      if (patientCoords == null || storeCoords == null) return 0.0;
      final distance=calculateDistance(
        storeCoords[1],
        storeCoords[0],
        patientCoords[1],
        patientCoords[0],
      );
      print(distance);

      return distance;

    } catch (e) {
      print('Distance calculation error: $e');
      return 0.0;
    }
  }
  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371.0; // Radius of Earth in km
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);
    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
            cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
                sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }
  double _degToRad(double deg) => deg * (pi / 180);

  /// Extracts [longitude, latitude] coordinates from GeoJSON-style location
  List<double>? extractCoordinates(Map<String, dynamic> location) {
    try {
      if (location['type'] == 'Point' && location['coordinates'] is List) {
        final coords = location['coordinates'];
        if (coords.length >= 2) {
          return [coords[0].toDouble(), coords[1].toDouble()];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  Future<void> submitBid(String requestId, double price, String nurseName, String serviceType,String distance) async {
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
        distance: distance
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
