import 'package:bson/bson.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../../../../mongodb/mongodb.dart';

class MyBookingsController extends GetxController {

  var unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUnreadBookingsCount();
  }
  // Fetch user bookings from the MongoDB collection
  Future<List<Map<String, dynamic>>> fetchUserBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) {
      throw Exception("User not logged in.");
    }

    try {
      // Query the database for bookings tied to the user's email
      final userBookings = await MongoDatabase.getPatientLabBookings(userEmail);
      if (userBookings != null) {
        return userBookings;
      }
    } catch (e) {
      print('Error fetching user bookings: $e');
    }

    return [];
  }
  Future<void> fetchUnreadBookingsCount() async {
    try {
      final bookings = await fetchUserBookings();
      final count = bookings.where((booking) =>
      booking['status'] == 'Pending' || booking['status'] == 'Modified').length;
      unreadCount.value = count;
    } catch (e) {
      print('Error fetching unread bookings count: $e');
      unreadCount.value = 0;
    }
  }

  // Add a new booking to the MongoDB collection
  Future<void> addBooking(
      String patientName, String testName, String bookingDate) async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) {
      print("Error: User not logged in.");
      return;
    }

    try {
      // Check if a similar booking already exists
      final existingBooking = await MongoDatabase.bookingsCollection?.findOne({
        'userEmail': userEmail,
        'patientName': patientName,
        'testName': testName,
        'bookingDate': bookingDate,
      });

      if (existingBooking == null) {
        // Insert the booking if it doesn't exist
        await MongoDatabase.bookingsCollection?.insertOne({
          'userEmail': userEmail,
          'patientName': patientName,
          'testName': testName,
          'bookingDate': bookingDate,
          'status': 'Pending', // Initialize with a default status
        });

        print('Booking added successfully: $patientName - $testName');
      } else {
        print('Booking already exists.');
      }
    } catch (e) {
      print('Error adding booking: $e');
    }
  }

  // Remove a booking from the MongoDB collection
  Future<void> removeBooking(String patientName) async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) {
      print("Error: User not logged in.");
      return;
    }

    try {
      // Query the booking by patient name and user email
      final userBooking = await MongoDatabase.bookingsCollection?.findOne({
        'userEmail': userEmail,
        'patientName': patientName,
      });

      if (userBooking != null) {
        // Delete the booking if found
        await MongoDatabase.bookingsCollection?.deleteOne({
          'userEmail': userEmail,
          'patientName': patientName,
        });

        print('Booking removed successfully.');
      } else {
        print('No matching booking found.');
      }
    } catch (e) {
      print('Error removing booking: $e');
    }
  }
  Future<void> rejectAndDeleteBooking(String bookingId) async {
    try {
      // Reject the booking first by updating its status in bookingsCollection (ObjectId)
      await MongoDatabase.bookingsCollection?.updateOne(
        {'_id': ObjectId.parse(bookingId)}, // Use ObjectId for bookingsCollection
        {'\$set': {'status': 'Rejected'}}, // Mark the booking as rejected
      );
      print('Booking status set to rejected in bookings collection.');

      // Delete from the bookings collection using ObjectId
      await MongoDatabase.bookingsCollection?.deleteOne(
        {'_id': ObjectId.parse(bookingId)}, // ObjectId for bookingsCollection
      );
      print('Booking deleted from bookings collection.');

      // Delete from the patientBookings collection using bookingId as String
      await MongoDatabase.patientBookingsCollection?.deleteOne(
        {'bookingId': bookingId}, // Use bookingId as String for patientBookingsCollection
      );
      print('Booking deleted from patientBookings collection.');
    } catch (e) {
      print('Error rejecting and deleting booking: $e');
    }
  }

  Future<bool> completeLabBooking(dynamic bookingId,String paymentMethod) async {
    return await updateBookingStatus(bookingId, 'Completed');
  }
  // Update the status of a booking
  Future<bool> updateBookingStatus(
      dynamic bookingId,
      String newStatus, {
        String? lastModifiedBy,
        String? paymentMethod,

      }) async {
    try {
      final updateDoc = {
        '\$set': {
          'status': newStatus,
          if (lastModifiedBy != null) 'lastModifiedBy': lastModifiedBy,
        }
      };

      // Update in bookingsCollection
      await MongoDatabase.bookingsCollection?.updateOne(
        {'_id': ObjectId.parse(bookingId)},
        updateDoc,
      );

      // Update in patientBookingsCollection
      await MongoDatabase.patientBookingsCollection?.updateOne(
        {'bookingId': ObjectId.parse(bookingId).toHexString()},
        updateDoc,
      );
      return true;
    } catch (e) {
      print('Error updating booking status: $e');
      rethrow;
    }
  }



  // Update the booking date
// Update the booking date
  Future<void> updateBookingDateAndStatus(
      String bookingId,
      String newDate,
      String newStatus, {
        required String lastModifiedBy,
      }) async {
    try {
      final updateDoc = {
        '\$set': {
          'bookingDate': newDate,
          'status': newStatus,
          'lastModifiedBy': lastModifiedBy,
        }
      };

      // Update in bookingsCollection
      await MongoDatabase.bookingsCollection?.updateOne(
        {'_id': ObjectId.parse(bookingId)},
        updateDoc,
      );

      // Update in patientBookingsCollection
      await MongoDatabase.patientBookingsCollection?.updateOne(
        {'bookingId': ObjectId.parse(bookingId).toHexString()},
        updateDoc,
      );
    } catch (e) {
      print('Error updating booking: $e');
      rethrow;
    }
  }
}



