import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicalStoreDashboardController extends GetxController {
  RxList<Map<String, dynamic>> bookings = <Map<String, dynamic>>[].obs;
  RxBool isLoading = true.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    try {
      isLoading.value = true;

      String uid = _auth.currentUser?.uid ?? '';

      // Assuming medical store UID is used to filter
      QuerySnapshot querySnapshot = await _firestore
          .collection('bookings')
          .where('storeId', isEqualTo: uid)
          .get();

      bookings.value = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error fetching bookings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      fetchBookings(); // Refresh
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  Future<void> saveDeviceToken(String token) async {
    String uid = _auth.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update({
        'deviceToken': token,
      });
    }
  }
}
