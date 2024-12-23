import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../../mongodb/mongodb.dart';

class BookingController {
  // Fetch user bookings from the MongoDB collection
  Future<List<Map<String, dynamic>>> fetchUserBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) {
      throw Exception("User not logged in.");
    }

    try {
      // Query the database for bookings tied to the user's email
      final userBookings = await MongoDatabase.bookingsCollection
          ?.find({'userEmail': userEmail}).toList();
      if (userBookings != null) {
        return userBookings;
      }
    } catch (e) {
      print('Error fetching user bookings: $e');
    }

    return [];
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
}
