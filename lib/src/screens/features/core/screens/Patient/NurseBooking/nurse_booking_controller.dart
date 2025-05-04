import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../notification_handler/send_notification.dart';
import 'bid_model.dart';
import 'nurseModel.dart';
class NurseBookingController extends GetxController {

   final mongoDatabase = MongoDatabase();

  Future<String> createServiceRequest({
    required String serviceType,
    required LatLng location,
    required String patientEmail,
    required String price
  }) async {
    final result = await MongoDatabase.createServiceRequest(
      patientEmail: patientEmail,
      serviceType: serviceType,
      servicePrice:price,
      location: location,
    );

    if (result.isNotEmpty) {

      return result; // already a hex string
    } else {
      throw Exception('Failed to insert service request');
    }
  }


  Future<List<Bid>> fetchBids(String requestId) async {
    try {
      final bidsData = await MongoDatabase.getBidsForRequest(requestId);
      return bidsData;
    } catch (e, stackTrace) {
      print('❌ Error fetching bids: $e');
      print(stackTrace);
      rethrow;
    }
  }


  static Future<void> acceptBid(String bidId, String patientEmail) async {
    try {
      final bidObjectId = ObjectId.parse(bidId);
      logger.i('🏁 Starting acceptBid process for bid: $bidId');

      // 1. Mark the bid as accepted
      logger.i('⚡ Updating bid status to accepted');
      final updateResult = await MongoDatabase.nurseBidsCollection?.updateOne(
        where.id(bidObjectId),
        modify.set('status', 'accepted'),
      );
      logger.i('📌 Bid update result: ${updateResult?.isSuccess}');

      // 2. Get the bid details
      logger.i('🔍 Fetching bid details');
      final bid = await MongoDatabase.nurseBidsCollection?.findOne(where.id(bidObjectId));
      logger.i('📄 Bid document: ${bid?.toString()}');

      final requestId = bid?['requestId'];
      final nurseEmail = bid?['nurseEmail'];
      final PatientEmail = patientEmail;
      final price = (bid?['price'] as num?)?.toDouble();

      // Validate required fields
      logger.i('🔎 Validating required fields');
      if (requestId == null || nurseEmail == null || PatientEmail == null || price == null) {
        logger.e('❌ Missing data: requestId:$requestId, nurseEmail:$nurseEmail, patientEmail:$PatientEmail, price:$price');
        throw Exception('Missing required bid information');
      }

      // 3. Get user details
      logger.i('👩⚕️ Fetching nurse details for: $nurseEmail');
      final nurse = await MongoDatabase.userNurseCollection?.findOne({'userEmail': nurseEmail});
      logger.i('👤 Fetching patient details for: $PatientEmail');
      final patient = await MongoDatabase.userPatientCollection?.findOne({'userEmail': PatientEmail});

      final nurseName = nurse?['userName'] ?? 'Unknown Nurse';
      final patientName = patient?['userName'] ?? 'Unknown Patient';

      // 4. Update service request
      logger.i('🔄 Updating service request status');
      final serviceUpdateResult = await MongoDatabase.nurseServiceRequestsCollection?.updateOne(
        where.id(ObjectId.parse(requestId)),
        modify
          ..set('status', 'accepted')
          ..set('acceptedBidId', bidId),
      );
      logger.i('📌 Service request update result: ${serviceUpdateResult?.isSuccess}');
        final location= await MongoDatabase.getUserLocationByEmail(PatientEmail);
      // 5. Prepare booking data
      logger.i('📦 Preparing booking data');
      final bookingData = {
        '_id': ObjectId(),
        'bookingId': bidId,
        'location': location,
        'patientEmail':PatientEmail,
        'nurseEmail': nurseEmail,
        'nurseName': nurseName,
        'patientName': patientName,
        'price': price,
        'status': 'accepted',
        'createdAt': DateTime.now().toUtc(),
      };


      final token = await MongoDatabase.getDeviceTokenByEmail(nurseEmail);

      print('📱 Device token fetched: $token');

      if (token == null) {
        print('❌ No device token found for $nurseEmail');
      } else {
        final notificationSent = await SendNotificationService.sendNotificationUsingApi(
          token: token,
          title: "$patientName have accepted your bid",
          body: "Tap to check bookings",
          data: {
            "screen": "MyBookedNursesScreen",
          },
        );

        print('📨 Notification sending result: ');
      }




      // 6. Insert into patient collection
      logger.i('💾 Saving to patient_Nurse_Bookings');
      if (MongoDatabase.patientNurseBookingsCollection == null) {
        logger.e('❌ patientNurseBookingsCollection is null!');
        throw Exception('Patient bookings collection not initialized');
      }
      final patientInsertResult = await MongoDatabase.patientNurseBookingsCollection?.insertOne(bookingData);
      logger.i('📌 Patient insert result: ${patientInsertResult?.isSuccess} ID: ${patientInsertResult?.id}');

      // 7. Insert into nurse collection
      logger.i('💾 Saving to nurse_Received_Bookings');
      if (MongoDatabase.nurseReceivedBookingsCollection == null) {
        logger.e('❌ nurseReceivedBookingsCollection is null!');
        throw Exception('Nurse bookings collection not initialized');
      }

      logger.i('✅ Bid acceptance process completed successfully');
    } catch (e, stackTrace) {
      logger.e('❌ Critical error in acceptBid:',
          error: e,
          stackTrace: stackTrace,
          time: DateTime.now()
      );
      rethrow;
    }
  }







  Future<void> cancelServiceRequest(String requestId) async {
    await mongoDatabase.deleteServiceRequestById(requestId);
  }





  Future<List<Nurse>> getNurseDetails(List<String> nurseEmails) async {
    try {
      final nurses = await MongoDatabase.getNursesByEmails(nurseEmails);
      return nurses;
    } catch (e) {
      print('Error fetching nurses: $e');
      return [];
    }
  }
}

