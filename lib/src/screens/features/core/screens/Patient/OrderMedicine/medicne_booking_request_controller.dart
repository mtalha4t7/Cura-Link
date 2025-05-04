import 'dart:convert';

import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'dart:io';
import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../notification_handler/send_notification.dart';
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

      final requestData = {
        'patientEmail': patientEmail,
        'medicines': medicineList,
        'prescriptionImage': encodedImage,
        'deliveryAddress': deliveryAddress,
        'subtotal': total - 50, // Assuming 50 is delivery fee
        'deliveryFee': 50.0,
        'total': total,
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
      final bids = await MongoDatabase.medicalBidsCollection?.find(
          where.eq('requestId', requestId)
      ).toList();

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

  Future<void> submitBid({
    required String requestId,
    required String storeEmail,
    required double bidAmount,
    required double originalAmount,
  }) async {
    try {
      final bidData = {
        'requestId': requestId,
        'storeEmail': storeEmail,
        'originalAmount': originalAmount,
        'bidAmount': bidAmount,
        'status': 'pending',
        'createdAt': DateTime.now().toUtc(),
      };

      final result = await MongoDatabase.medicalBidsCollection?.insertOne(bidData);

      if (result?.isSuccess != true) {
        throw Exception('Failed to submit bid');
      }

      // Notify patient
      await _notifyPatientAboutBid(requestId, storeEmail);
    } catch (e) {
      print('Error submitting bid: $e');
      rethrow;
    }
  }

  Future<void> _notifyPatientAboutBid(String requestId, String storeEmail) async {
    try {
      // Get request to find patient
      final request = await MongoDatabase.medicalRequestsCollection?.findOne(
          where.id(ObjectId.parse(requestId))
      );

      if (request == null) return;

      final patientEmail = request['patientEmail'];
      final patient = await MongoDatabase.userPatientCollection?.findOne(
          where.eq('userEmail', patientEmail)
      );

      final deviceToken = patient?['deviceToken'];
      final store = await MongoDatabase.userMedicalStoreCollection?.findOne(
          where.eq('userEmail', storeEmail)
      );

      final storeName = store?['storeName'] ?? 'A pharmacy';

      if (deviceToken != null && deviceToken.isNotEmpty) {
        await SendNotificationService.sendNotificationUsingApi(
          token: deviceToken,
          title: "New Bid Received",
          body: "$storeName has submitted a bid for your request",
          data: {
            "screen": "MedicalRequestDetails",
            "requestId": requestId,
          },
        );
      }
    } catch (e) {
      print('Error notifying patient: $e');
    }
  }

  Future<void> acceptBid(String bidId, String patientEmail) async {
    try {
      final bidObjectId = ObjectId.parse(bidId);

      // 1. Update bid status
      await MongoDatabase.medicalBidsCollection?.updateOne(
        where.id(bidObjectId),
        modify.set('status', 'accepted'),
      );

      // 2. Get bid details
      final bid = await MongoDatabase.medicalBidsCollection?.findOne(
          where.id(bidObjectId)
      );

      if (bid == null) throw Exception('Bid not found');

      final requestId = bid['requestId'];
      final storeEmail = bid['storeEmail'];
      final bidAmount = bid['bidAmount'];

      // 3. Update request status
      await MongoDatabase.medicalRequestsCollection?.updateOne(
        where.id(ObjectId.parse(requestId)),
        modify
          ..set('status', 'accepted')
          ..set('acceptedBidId', bidId)
          ..set('acceptedAmount', bidAmount),
      );

      // 4. Create order record
      final orderData = {
        'requestId': requestId,
        'bidId': bidId,
        'patientEmail': patientEmail,
        'storeEmail': storeEmail,
        'finalAmount': bidAmount,
        'status': 'preparing', // preparing, dispatched, delivered
        'createdAt': DateTime.now().toUtc(),
      };

      await MongoDatabase.medicalOrdersCollection?.insertOne(orderData);

      // 5. Notify store
      await _notifyStoreAboutAcceptedBid(storeEmail, requestId);
    } catch (e) {
      print('Error accepting bid: $e');
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