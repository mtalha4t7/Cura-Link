
import 'package:cura_link/src/screens/features/core/screens/Patient/NurseBooking/temp_user_NurseModel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:mongo_dart/mongo_dart.dart';

import '../../../../../../mongodb/mongodb.dart';
import 'bid_model.dart';
import 'nurseModel.dart';
class NurseBookingController extends GetxController {

  final mongoDatabase = MongoDatabase();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createServiceRequest({
    required String serviceType,
    required LatLng location,
    required String patientEmail,
  }) async {
    final result = await MongoDatabase.createServiceRequest(
      patientEmail: patientEmail,
      serviceType: serviceType,
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


  Future<void> acceptBid(String bidId) async {
    await MongoDatabase.acceptBid(bidId);
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

