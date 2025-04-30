
import 'package:cura_link/src/screens/features/core/screens/Patient/NurseBooking/temp_user_NurseModel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:mongo_dart/mongo_dart.dart';

import '../../../../../../mongodb/mongodb.dart';
import 'bid_model.dart';
class NurseBookingController extends GetxController {

  final mongoDatabase = MongoDatabase();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createServiceRequest({
    required String serviceType,
    required LatLng location, required String requestId,
  }) async {
    final patientEmail = _auth.currentUser?.email;
    if (patientEmail == null) throw Exception('User not logged in');

    return await MongoDatabase.createServiceRequest(
      patientEmail: patientEmail,
      serviceType: serviceType,
      location: location,
    );
  }

  Future<List<Bid>> fetchBids(String requestId) async {
    try {
      final bidsData = await MongoDatabase.getBidsForRequest(requestId);
      return bidsData.map((bid) => Bid.fromMap(bid)).toList();
    } catch (e) {
      print('Error fetching bids: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> acceptBid(String bidId) async {
    await MongoDatabase.acceptBid(bidId);
  }

  Future<void> cancelServiceRequest(String requestId) async {
    await mongoDatabase.deleteServiceRequestById(requestId);
  }





  Future<List<ShowNurseUserModel>> getNurseDetails(List<String> nurseEmails) async {
    final nurses = await MongoDatabase.userNurseCollection?.find(
        where.oneFrom('userEmail', nurseEmails)
    ).toList();

    return nurses?.map((nurse) => ShowNurseUserModel.fromJson(nurse)).toList() ?? [];
  }
}
// Existing Nurse User Model (should be in separate file)
