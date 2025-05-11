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
   var _storeLocation;

  static const double BASE_DELIVERY_FEE = 50.0; // Base delivery fee in PKR
  static const double PER_KM_RATE = 20.0; // Additional fee per km
  static const double MIN_DELIVERY_FEE = 40.0; // Minimum delivery fee
  static const double MAX_DELIVERY_FEE = 500.0; // Maximum delivery fee

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
     final email=currentUser?.email;
       _storeLocation = await MongoDatabase.getUserLocationByEmail(email!);
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
      String patientEmail,
      double deliveryFee,
      double totalPrice,
      double basePrice,
      String storeName, {
        String? prescriptionDetails,
        List<dynamic>? medicines,
        String? prescriptionImage,
      }) async {
    try {
      isLoading(true);
      print("==================== $storeName");

      final email = FirebaseAuth.instance.currentUser?.email;
      if (email == null) {
        throw Exception("Store email is null. User might not be logged in.");
      }
         print(patientEmail);
      if (patientEmail == null) {
        throw Exception("Patient email is null. Cannot submit bid.");
      }

      final storeLocation = await MongoDatabase.getUserLocationByEmail(email);
      final patientLocation = await MongoDatabase.getUserLocationByEmail(patientEmail);

      final distanceInKm = await calculateDistanceBetweenLocations(patientLocation!);
      String distanceString = distanceInKm < 1.0
          ? '${(distanceInKm * 1000).round()}m'
          : '${distanceInKm.toStringAsFixed(1)} km';
      final deliveryTime = (storeLocation != null && patientLocation != null)
          ? calculateDeliveryTime(patientLocation, storeLocation)
          : '30-45 min';

      final bidData = {
        'storeName': storeName,
        'storeEmail': medicalStore.value?.userEmail ?? '',
        'Base-price': basePrice,
        'deliveryFee': deliveryFee,
        'Distance' :distanceString,
        'submittedAt': DateTime.now(),
        'deliveryTime': deliveryTime,
        'requestId':requestId,
        if (prescriptionDetails != null)
          'prescriptionDetails': prescriptionDetails,
        if (medicines != null)
          'medicines': medicines,
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



  Future<double> calculateDistanceBetweenLocations(Map<String, dynamic> patientLocation) async {
    try {
      if (_storeLocation == null || patientLocation.isEmpty) return 0.0;

      final patientCoords = extractCoordinates(patientLocation);
      print('storeee $_storeLocation');
      print('patient $patientLocation');
      final storeCoords = extractCoordinates(_storeLocation!);

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

  Future<Map<String, double>> getDeliveryDetails(Map<String, dynamic> patientLocation) async {
    final distance = await calculateDistanceBetweenLocations(patientLocation);
    final fee = await calculateDeliveryFee(patientLocation);
    return {
      'distance': distance,
      'fee': fee,
    };
  }

  Future<double> calculateDeliveryFee(Map<String, dynamic> patientLocation) async {
    try {
      final distance = await calculateDistanceBetweenLocations(patientLocation);
      double fee = BASE_DELIVERY_FEE + (distance * PER_KM_RATE);
      return fee.clamp(MIN_DELIVERY_FEE, MAX_DELIVERY_FEE);
    } catch (e) {
      print("Error calculating delivery fee: $e");
      return MIN_DELIVERY_FEE;
    }
  }

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

  /// Haversine formula to calculate distance in kilometers
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



// New function to calculate delivery fee
  double _calculateDeliveryFee(
      Map<String, dynamic> patientLocation,
      Map<String, dynamic> storeLocation,
      ) {
    try {
      final patientCoords = _extractCoordinates(patientLocation);
      final storeCoords = _extractCoordinates(storeLocation);

      if (patientCoords == null || storeCoords == null) {
        return MIN_DELIVERY_FEE;
      }

      final distance = _calculateDistance(
        storeCoords[1], // lat
        storeCoords[0], // lng
        patientCoords[1], // lat
        patientCoords[0], // lng
      );

      // Calculate fee: base + (distance * per km rate)
      double fee = BASE_DELIVERY_FEE + (distance * PER_KM_RATE);

      // Apply min/max bounds
      fee = fee.clamp(MIN_DELIVERY_FEE, MAX_DELIVERY_FEE);

      // Round to nearest 10
      return (fee / 10).roundToDouble() * 10;
    } catch (e) {
      print("Error calculating delivery fee: $e");
      return MIN_DELIVERY_FEE;
    }
  }

// Update the calculateDeliveryTime function to use the same distance calculation
  String calculateDeliveryTime(
      Map<String, dynamic>? patientLocation,
      Map<String, dynamic>? storeLocation,
      ) {
    print("Patient Location: $patientLocation");
    print("Store Location: $storeLocation");

    try {
      if (patientLocation == null || storeLocation == null) {
        return '30-45 mins';
      }

      final patientCoords = _extractCoordinates(patientLocation);
      final storeCoords = _extractCoordinates(storeLocation);

      print("Patient Coords: $patientCoords");
      print("Store Coords: $storeCoords");

      if (patientCoords == null || storeCoords == null) {
        return '30-45 mins';
      }

      final distance = _calculateDistance(
        storeCoords[1], // lat
        storeCoords[0], // lng
        patientCoords[1], // lat
        patientCoords[0], // lng
      );

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