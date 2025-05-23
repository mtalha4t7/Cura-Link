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
    final availableNurses = await MongoDatabase.getAvailableNurses();

    if (availableNurses != null && availableNurses.isNotEmpty) {
      for (var nurse in availableNurses) {
        final deviceToken = nurse['userDeviceToken'];
        final userName = nurse['userName'];
        if (deviceToken != null && deviceToken.isNotEmpty) {
          await SendNotificationService.sendNotificationUsingApi(
            token: deviceToken,
            title: "$userName check New Booking Request",
            body: "Someone has requested a $serviceType service. Tap to bid!",
            data: {
              "screen": "NurseBookingsScreen",
            },
          );
        }
      }
    } else {
      print("No available nurses found.");
    }
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
       final serviceName = bid?['serviceName'];
       final price = (bid?['price'] as num?)?.toDouble();

       // Validate required fields
       logger.i('🔎 Validating required fields');
       if (requestId == null || nurseEmail == null || patientEmail == null || price == null) {
         logger.e('❌ Missing data: requestId:$requestId, nurseEmail:$nurseEmail, patientEmail:$patientEmail, price:$price');
         throw Exception('Missing required bid information');
       }

       // 3. Get user details
       logger.i('👩⚕️ Fetching nurse details for: $nurseEmail');
       final nurse = await MongoDatabase.userNurseCollection?.findOne({'userEmail': nurseEmail});
       logger.i('👤 Fetching patient details for: $patientEmail');
       final patient = await MongoDatabase.userPatientCollection?.findOne({'userEmail': patientEmail});

       final nurseName = nurse?['userName'] ?? 'Unknown Nurse';
       final patientName = patient?['userName'] ?? 'Unknown Patient';

       // 4. Update service request
       logger.i('🔄 Updating service request status');
       final serviceUpdateResult = await MongoDatabase.nurseServiceRequestsCollection?.updateOne(
         where.id(ObjectId.parse(requestId)),
         modify
           ..set('status', 'accepted')
           ..set('acceptedBidId', bidId)
          ,
       );
       logger.i('📌 Service request update result: ${serviceUpdateResult?.isSuccess}');

       final location = await MongoDatabase.getUserLocationByEmail(patientEmail);

       // 5. Prepare booking data
       logger.i('📦 Preparing booking data');
       final bookingData = {
         '_id': ObjectId(),
         'bookingId': bidId,
         'location': location,
         'patientEmail': patientEmail,
         'serviceName': serviceName,
         'nurseEmail': nurseEmail,
         'nurseName': nurseName,
         'patientName': patientName,
         'price': price,
         'status': 'accepted',
         'createdAt': DateTime.now().toUtc().add(Duration(hours:5)),
       };

       // 6. Send notification to nurse
       final token = await MongoDatabase.getDeviceTokenByEmail(nurseEmail);
       if (token != null) {
         await SendNotificationService.sendNotificationUsingApi(
           token: token,
           title: "$patientName has accepted your bid",
           body: "Tap to check bookings",
           data: {"screen": "MyBookedNursesScreen"},
         );
       }

       // 7. Insert into patient collection
       logger.i('💾 Saving to patient_Nurse_Bookings');
       await MongoDatabase.patientNurseBookingsCollection?.insertOne(bookingData);

       // 8. Insert into nurse collection
       logger.i('💾 Saving to nurse_Received_Bookings');
       await MongoDatabase.nurseReceivedBookingsCollection?.insertOne(bookingData);

       logger.i('✅ Bid acceptance process completed successfully');
     } catch (e, stackTrace) {
       logger.e('❌ Critical error in acceptBid:',
           error: e,
           stackTrace: stackTrace,
           time: DateTime.now().toUtc().add(Duration(hours:5)),
       );
       rethrow;
     }
   }

   Future<void> cancelServiceRequest(String requestId) async {
     try {
       // Step 1: Delete the service request
       await mongoDatabase.deleteServiceRequestById(requestId);
       print("Service request $requestId deleted successfully");

       // Step 2: Notify available nurses
       final availableNurses = await MongoDatabase.getAvailableNurses();
       print("Found ${availableNurses?.length ?? 0} available nurses");

       if (availableNurses != null && availableNurses.isNotEmpty) {
         for (var nurse in availableNurses) {
           try {
             final deviceToken = nurse['userDeviceToken']?.toString();
             final userName = nurse['userName']?.toString();

             print("Processing nurse: $userName with token: $deviceToken");

             if (deviceToken != null && deviceToken.isNotEmpty) {
               print("Attempting to send notification to $userName");

               final response = await SendNotificationService.sendNotificationUsingApi(
                 token: deviceToken,
                 title: "Service Request Cancelled",
                 body: "$userName has cancelled their service request.",
                 data: {
                   "screen": "NurseBookingsScreen",
                 },
               );

               print("Notification sent successfully to $userName");
             } else {
               print("Skipping nurse $userName - no device token");
             }
           } catch (e) {
             print("Error sending notification to nurse: $e");
           }
         }
       } else {
         print("No available nurses found to notify about cancellation.");
       }
     } catch (e) {
       print("Error in cancelServiceRequest: $e");
     }
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

