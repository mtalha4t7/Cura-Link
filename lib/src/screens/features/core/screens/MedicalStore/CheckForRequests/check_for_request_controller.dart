import 'dart:async';
import 'dart:math';
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
        String? patientEmail,
      }) async {
    try {
      isLoading(true);
      print("====================" + storeName);

      final email = await FirebaseAuth.instance.currentUser?.email;
      final storeLocation = await MongoDatabase.getUserLocationByEmail(email!);
      final patientLocation=await MongoDatabase.getUserLocationByEmail(patientEmail!);
      print(patientLocation);
      print("ahhahahahah");
      print(storeLocation);
      // Calculate delivery time
      final deliveryTime = patientLocation != null
          ? calculateDeliveryTime(patientLocation, storeLocation!)
          : '30-45 min'; // Default if location not available
      // Prepare bid data
      final bidData = {
        'storeName': storeName,
        'storeEmail': medicalStore.value?.userEmail ?? '',
        'price': price,
        'submittedAt': DateTime.now(),
        'deliveryTime': deliveryTime,
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

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371; // Earth's radius in km

    // Convert degrees to radians
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        sin(dLat/2) * sin(dLat/2) +
            cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
                sin(dLon/2) * sin(dLon/2);

    final c = 2 * atan2(sqrt(a), sqrt(1-a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

// Function to calculate estimated delivery time in minutes
  String calculateDeliveryTime(
      Map<String, dynamic>? patientLocation,
      Map<String, dynamic>? storeLocation) {
    print("Patient Location: $patientLocation");
    print("Store Location: $storeLocation");

    try {
      // If either location is null, return default
      if (patientLocation == null || storeLocation == null) {
        return '30-45 mins';
      }

      // Extract coordinates from GeoJSON format
      final patientCoords = _extractCoordinates(patientLocation);
      final storeCoords = _extractCoordinates(storeLocation);

      print("Patient Coords: $patientCoords");
      print("Store Coords: $storeCoords");

      // Get coordinates with null checks
      final patientLat = patientCoords?[1] ?? 0.0; // Latitude is second in GeoJSON
      final patientLng = patientCoords?[0] ?? 0.0; // Longitude is first in GeoJSON
      final storeLat = storeCoords?[1] ?? 0.0;
      final storeLng = storeCoords?[0] ?? 0.0;

      // If coordinates are zero (default), return estimated time
      if (patientLat == 0.0 && patientLng == 0.0 ||
          storeLat == 0.0 && storeLng == 0.0) {
        return '30-45 mins';
      }

      // Calculate distance in km
      final distance = _calculateDistance(storeLat, storeLng, patientLat, patientLng);
      print("Distance: ${distance.toStringAsFixed(2)} km");

      // Average delivery speed (km/h)
      const averageSpeed = 30.0;

      // Calculate time in hours, then convert to minutes
      final timeInHours = distance / averageSpeed;
      final totalMinutes = (timeInHours * 60).round();

      // Add buffer time for preparation (15 minutes)
      final estimatedMinutes = totalMinutes + 15;

      // Format the output
      if (estimatedMinutes < 60) {
        return '$estimatedMinutes mins';
      } else {
        final hours = estimatedMinutes ~/ 60;
        final mins = estimatedMinutes % 60;
        return '${hours}h ${mins}m';
      }
    } catch (e) {
      print("Error calculating delivery time: $e");
      return '30-45 mins';
    }
  }

  List<double>? _extractCoordinates(Map<String, dynamic> location) {
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