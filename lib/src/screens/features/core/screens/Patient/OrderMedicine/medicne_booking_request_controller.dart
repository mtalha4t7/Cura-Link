import 'dart:convert';

import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'dart:io';
import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../notification_handler/send_notification.dart';
import '../../../utils/location_utils.dart';
import 'medical_store_model.dart';
import 'order_model.dart';

class MedicalStoreController extends GetxController {
  final mongoDatabase = MongoDatabase();


  Future<String> createMedicalRequest({
    required List<Map<String, dynamic>> medicines,
    required String patientEmail,
    required String deliveryAddress,
    required double total,
    File? prescriptionImage,
  }) async {
    try {
      String? encodedImage;
      String requestType;
      List<Map<String, dynamic>>? medicineList;

      if (prescriptionImage != null) {
        // Encode image to Base64
        final bytes = await prescriptionImage.readAsBytes();
        encodedImage = base64Encode(bytes);
        requestType = 'prescription';
        medicineList = []; // Don't include medicine details
      } else {
        requestType = 'notPrescription';
        medicineList = medicines.map((m) => {
          'name': m['name'],
          'price': m['price'],
          'quantity': m['quantity'] ?? 1,
          'category': m['category'],
        }).toList();
      }
      final patientLocation = await MongoDatabase.getLocationByEmail(patientEmail);
      final patientName= await UserRepository.instance.getFullNameByEmail(email: patientEmail, collection: MongoDatabase.userPatientCollection);
      final requestData = {
        'patientEmail': patientEmail,
        'patientName':patientName,
        'medicines': medicineList,
        'prescriptionImage': encodedImage,
        'deliveryAddress': deliveryAddress,
        'subtotal': total - 0, // Assuming 50 is delivery fee
        'deliveryFee': 00.0,
        'total': total,
        'patientLocation':patientLocation,
        'status': 'pending', // pending, bid_submitted, accepted, completed
        'requestType': requestType, // <-- new field
        'createdAt': DateTime.now().toUtc(),
        'updatedAt': DateTime.now().toUtc(),
      };

      final result = await MongoDatabase.medicalRequestsCollection?.insertOne(requestData);

      if (result?.isSuccess != true || result?.id == null) {
        throw Exception('Failed to create medical request');
      }

      await _notifyMedicalStores(result!.id.toString());

      return result.id.toString();
    } catch (e) {
      print('Error creating medical request: $e');
      rethrow;
    }
  }


  Future<void> _notifyMedicalStores(String requestId) async {
    try {
      final stores = await MongoDatabase.getMedicalStores();

      for (var store in stores) {
        final deviceToken = store['deviceToken'];
        if (deviceToken != null && deviceToken.isNotEmpty) {
          await SendNotificationService.sendNotificationUsingApi(
            token: deviceToken,
            title: "New Medicine Request Available",
            body: "A patient has requested medicines. Tap to view details.",
            data: {
              "screen": "MedicalStoreRequests",
              "requestId": requestId,
            },
          );
        }
      }
    } catch (e) {
      print('Error notifying stores: $e');
    }
  }

  Future<List<MedicalStoreBid>> fetchBidsForRequest(String requestId) async {
    try {
      final cleanId = cleanObjectId(requestId);
      final bids = await MongoDatabase.medicalBidsCollection?.find(
          where.eq('requestId', cleanId)
      ).toList();
      print(bids);
      return bids?.map((b) => MedicalStoreBid.fromMap(b)).toList() ?? [];
    } catch (e) {
      print('Error fetching bids: $e');
      rethrow;
    }
  }
  Future<MedicalStoreOrder> getOrderDetails(String orderId) async {
    try {
      final order = await MongoDatabase.medicalOrdersCollection?.findOne(
          where.id(ObjectId.parse(orderId))
      );

      if (order == null) throw Exception('Order not found');

      final request = await MongoDatabase.medicalRequestsCollection?.findOne(
          where.id(ObjectId.parse(order['requestId']))
      );

      final store = await MongoDatabase.userMedicalStoreCollection?.findOne(
          where.eq('userEmail', order['storeEmail'])
      );

      final patient = await MongoDatabase.userPatientCollection?.findOne(
          where.eq('userEmail', order['patientEmail'])
      );

      return MedicalStoreOrder.fromMap({
        ...order,
        'medicines': request?['medicines'] ?? [],
        'prescriptionImage': request?['prescriptionImage'],
        'storeName': store?['storeName'],
        'storePhone': store?['phoneNumber'],
        'patientName': patient?['userName'],
        'patientLocation': patient?['location'] ?? patient?['userAddress'],
      });
    } catch (e) {
      print('Error fetching order details: $e');
      rethrow;
    }
  }



  Future<void> acceptBid(String bidId, String patientEmail) async {
    try {
      // 1. Update bid status
      final result = await MongoDatabase.medicalBidsCollection?.updateOne(
        where.eq('requestId', bidId),
        modify.set('status', 'accepted'),
      );

      print('Update result: ${result?.isSuccess}'); // Debugging

      // 2. Get bid details
      final bid = await MongoDatabase.medicalBidsCollection?.findOne(
        where.eq('requestId', bidId),
      );
    final patient= await MongoDatabase.userPatientCollection?.findOne(
        where.eq('userEmail', patientEmail),
      );

      print(bidId); // Prints String
      print(bid);   // Should not be null

      if (bid == null) throw Exception('Bid not found');

      final requestId = bid['requestId'];
      final storeEmail = bid['storeEmail'];
      final bidAmount = bid['totalPrice'];
      final storeName = bid['storeName'];
      final distance = bid['Distance'];
      final deliveryTimeString = bid['deliveryTime'];
      final patientName= patient!['userName'];


      // Parse the delivery time string to get minutes
      final minutes = _parseDeliveryTime(deliveryTimeString);

      // Calculate expected delivery time (current time + parsed minutes)
      final createdAt = DateTime.now().toUtc();
      final expectedDeliveryTime = createdAt.add(Duration(minutes: minutes));

      // 3. Update medical request status
      await MongoDatabase.medicalRequestsCollection?.updateOne(
        where.eq('_id', cleanObjectId(requestId)),
        modify
          ..set('status', 'accepted')
          ..set('acceptedBidId', bidId)
          ..set('acceptedAmount', bidAmount),
      );

      final patientLocation = await MongoDatabase.getLocationByEmail(patientEmail);

      // 4. Insert order
      final orderData = {
        'requestId': requestId,
        'bidId': bidId,
        'patientLocation': patientLocation,
        'distance': distance,
        'patientEmail': patientEmail,
        'patientName':patientName,
        'storeName': storeName,
        'storeEmail': storeEmail,
        'finalAmount': bidAmount,
        'status': 'preparing',
        'createdAt': createdAt,
        'expectedDeliveryTime': expectedDeliveryTime,
        'deliveryTime': deliveryTimeString, // Keep the original string format
      };

      await MongoDatabase.medicalOrdersCollection?.insertOne(orderData);

      // 5. Notify
      await _notifyStoreAboutAcceptedBid(storeEmail, requestId);
    } catch (e) {
      print('Error accepting bid: $e');
      rethrow;
    }
  }

  // Helper function to parse delivery time string (e.g., "16 mins" → 16)
  int _parseDeliveryTime(String deliveryTime) {
    try {
      // Remove all non-digit characters and parse to int
      final minutes = int.parse(deliveryTime.replaceAll(RegExp(r'[^0-9]'), ''));
      return minutes;
    } catch (e) {
      print('Error parsing delivery time, defaulting to 30 minutes: $e');
      return 30; // Default fallback value
    }
  }




  Future<Map<String, dynamic>> calculateDeliveryTime(String requestId) async {
    try {
      // Get the request details
      final request = await MongoDatabase.medicalRequestsCollection?.findOne(
          where.id(ObjectId.parse(requestId))
      );

      // Get store location
      final storeLocation = await MongoDatabase.getLocationByEmail(request?['storeEmail']);

      final storeLat = storeLocation?['latitude']?.toDouble();
      final storeLon = storeLocation?['longitude']?.toDouble();

      if (storeLat == null || storeLon == null) {
        throw Exception('Store location not available');
      }

      // Get patient location from request
      final patientLocation = request?['location'];
      final patientLat = patientLocation['latitude']?.toDouble();
      final patientLon = patientLocation['longitude']?.toDouble();

      if (patientLat == null || patientLon == null) {
        throw Exception('Patient location not available');
      }

      // Calculate delivery time
      final deliveryTimeMinutes = LocationUtils.calculateDeliveryTime(
        storeLat,
        storeLon,
        patientLat,
        patientLon,
      );

      return {
        'distance': LocationUtils.calculateDistance(storeLat, storeLon, patientLat, patientLon),
        'time': deliveryTimeMinutes,
        'formattedTime': LocationUtils.formatDeliveryTime(deliveryTimeMinutes),
      };
    } catch (e) {
      print('Error calculating delivery time: $e');
      rethrow;
    }
  }


  Future<void> _notifyStoreAboutAcceptedBid(String storeEmail, String requestId) async {
    try {
      final store = await MongoDatabase.userMedicalStoreCollection?.findOne(
          where.eq('userEmail', storeEmail)
      );

      final deviceToken = store?['deviceToken'];

      if (deviceToken != null && deviceToken.isNotEmpty) {
        await SendNotificationService.sendNotificationUsingApi(
          token: deviceToken,
          title: "Bid Accepted!",
          body: "A patient has accepted your bid. Prepare the order.",
          data: {
            "screen": "StoreOrders",
            "requestId": requestId,
          },
        );
      }
    } catch (e) {
      print('Error notifying store: $e');
    }
  }
  String cleanObjectId(String rawId) {
    if (rawId.contains('ObjectId')) {
      // Remove 'ObjectId("', 'ObjectId(\'', and ending '")' or '\')'
      return rawId
          .replaceAll('ObjectId("', '')
          .replaceAll('ObjectId(\'', '')
          .replaceAll('")', '')
          .replaceAll('\')', '');
    }
    return rawId;
  }
  Future<void> cancelRequest(String requestId) async {
    try {
      // Make sure requestId is clean (just the 24-char hex string)
      final cleanId = cleanObjectId(requestId);

      print('================= $cleanId');

      await MongoDatabase.medicalRequestsCollection?.deleteOne(
        where.id(ObjectId.parse(cleanId)),
      );

      // Optionally notify stores/bidders about cancellation
    } catch (e) {
      print('Error cancelling request: $e');
      rethrow;
    }
  }

  Future<List<MedicalStoreRequest>> getPatientRequests(String patientEmail) async {
    try {
      final requests = await MongoDatabase.medicalRequestsCollection?.find(
          where.eq('patientEmail', patientEmail)
              .sortBy('createdAt', descending: true)
      ).toList();

      return requests?.map((r) => MedicalStoreRequest.fromMap(r)).toList() ?? [];
    } catch (e) {
      print('Error fetching patient requests: $e');
      rethrow;
    }
  }

  Future<List<MedicalStoreRequest>> getStoreRequests(String storeEmail) async {
    try {
      // Get requests that don't have accepted bids yet
      final requests = await MongoDatabase.medicalRequestsCollection?.find(
          where.eq('status', 'pending')
              .sortBy('createdAt', descending: true)
      ).toList();

      return requests?.map((r) => MedicalStoreRequest.fromMap(r)).toList() ?? [];
    } catch (e) {
      print('Error fetching store requests: $e');
      rethrow;
    }
  }

}