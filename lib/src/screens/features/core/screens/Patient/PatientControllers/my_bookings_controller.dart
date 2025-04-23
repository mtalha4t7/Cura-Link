import 'package:bson/bson.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../../mongodb/mongodb.dart';

class MyBookingsController {
  // Fetch user bookings from the MongoDB collection
  Future<List<Map<String, dynamic>>> fetchUserBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) {
      throw Exception("User not logged in.");
    }

    try {
      // Query the database for bookings tied to the user's email
      final userBookings = await MongoDatabase.patientBookingsCollection
          ?.find({'patientUserEmail': userEmail}).toList();
      if (userBookings != null) {
        return userBookings;
      }
    } catch (e) {
      print('Error fetching user bookings: $e');
    }

    return [];
  }
  Future<int> fetchUnreadBookingsCount() async {
    try {
      final bookings = await fetchUserBookings();
      final unreadCount = bookings.where((booking) =>
      booking['status'] == 'Pending' || booking['status'] == 'Modified').length;
      return unreadCount;
    } catch (e) {
      print('Error fetching unread bookings count: $e');
      return 0;
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


  // Update the status of a booking
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      print('Attempting to update booking ID: $bookingId to status: $newStatus');

      // Convert bookingId to ObjectId
      final objectId = ObjectId.parse(bookingId);
      final bookingIdAsString = objectId.toHexString(); // Convert to string

      print('Parsed ObjectId: $objectId');

      // Update the status in bookingsCollection
      final result = await MongoDatabase.bookingsCollection?.updateOne(
        {'_id': objectId}, // Use ObjectId for labBookings
        {'\$set': {'status': newStatus}},
      );

      if (result != null && result.isSuccess) {
        print('Booking status updated successfully in bookings collection.');
      } else {
        print('Update failed in bookings collection. Result: $result');
      }

      // Check if a matching document exists in patientBookingsCollection
      final existingPatientBooking = await MongoDatabase.patientBookingsCollection?.findOne({
        'bookingId': bookingIdAsString, // Use string for patientBookings
      });

      print('Existing booking in patientBookings collection: $existingPatientBooking');

      if (existingPatientBooking != null) {
        // Update the status in patientBookingsCollection
        final updateResult = await MongoDatabase.patientBookingsCollection?.updateOne(
          {'bookingId': bookingIdAsString}, // Match as string
          {'\$set': {'status': newStatus}},
        );

        if (updateResult != null && updateResult.isSuccess) {
          print('Booking status updated successfully in patientBookings collection.');
        } else {
          print('Update failed in patientBookings collection. Result: $updateResult');
        }
      } else {
        print('No matching document found in patientBookings collection. Skipping update.');
      }
    } catch (e) {
      print('Error updating booking status: $e');
    }
  }




// Update the booking date
  Future<void> updateBookingDate(String bookingId, String newDate) async {
    try {
      print('Attempting to update booking date for booking ID: $bookingId to date: $newDate');

      // Convert bookingId to ObjectId
      final objectId = ObjectId.parse(bookingId);
      final bookingIdAsString = objectId.toHexString(); // Convert to string for patientBookingsCollection

      // Update the bookingDate in bookingsCollection
      final result = await MongoDatabase.bookingsCollection?.updateOne(
        {'_id': objectId}, // Filter by ObjectId
        {'\$set': {'bookingDate': newDate}}, // Update the booking date
      );

      if (result != null && result.isSuccess) {
        print('Booking date updated successfully in bookings collection.');
      } else {
        print('Update failed in bookings collection. Result: $result');
      }

      // Check if a matching document exists in patientBookingsCollection
      final existingPatientBooking = await MongoDatabase.patientBookingsCollection?.findOne({
        'bookingId': bookingIdAsString, // Query as a string
      });

      print('Existing booking in patientBookings collection: $existingPatientBooking');

      if (existingPatientBooking != null) {
        // Update the bookingDate in patientBookingsCollection
        final updateResult = await MongoDatabase.patientBookingsCollection?.updateOne(
          {'bookingId': bookingIdAsString}, // Match as string
          {'\$set': {'bookingDate': newDate}},
        );

        if (updateResult != null && updateResult.isSuccess) {
          print('Booking date updated successfully in patientBookings collection.');
        } else {
          print('Update failed in patientBookings collection. Result: $updateResult');
        }
      } else {
        print('No matching document found in patientBookings collection. Skipping update.');
      }
    } catch (e) {
      print('Error updating booking date: $e');
    }
  }

}
