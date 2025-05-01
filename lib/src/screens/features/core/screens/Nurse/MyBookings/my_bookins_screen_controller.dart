import 'package:mongo_dart/mongo_dart.dart';
import 'package:logger/logger.dart';

import '../../../../../../mongodb/mongodb.dart';

class MyBookingsNurseController {
  final Logger _logger = Logger();

  // Fetch all bookings for the current nurse
  Future<List<Map<String, dynamic>>> fetchNurseBookings(String nurseEmail) async {
    try {
      final bookings = await MongoDatabase.patientNurseBookingsCollection?.find(
          where.eq('nurseEmail', nurseEmail)
              .sortBy('bookingDate', descending: false) // Show upcoming first
      ).toList();

      return bookings ?? [];
    } catch (e, stackTrace) {
      _logger.e('Error fetching nurse bookings', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      final id = ObjectId.parse(bookingId);
      final result = await MongoDatabase.patientNurseBookingsCollection?.updateOne(
        where.id(id),
        modify
            .set('status', newStatus)
            .set('updatedAt', DateTime.now()),
      );

      return result?.isSuccess ?? false;
    } catch (e, stackTrace) {
      _logger.e('Error updating booking status', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    try {
      return await updateBookingStatus(bookingId, 'Cancelled');
    } catch (e, stackTrace) {
      _logger.e('Error cancelling booking', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // Complete a booking
  Future<bool> completeBooking(String bookingId) async {
    try {
      return await updateBookingStatus(bookingId, 'Completed');
    } catch (e, stackTrace) {
      _logger.e('Error completing booking', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // Get booking details by ID
  Future<Map<String, dynamic>?> getBookingDetails(String bookingId) async {
    try {
      final id = ObjectId.parse(bookingId);
      return await MongoDatabase.patientNurseBookingsCollection?.findOne(where.id(id));
    } catch (e, stackTrace) {
      _logger.e('Error getting booking details', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // Get upcoming bookings (status not completed or cancelled)
  Future<List<Map<String, dynamic>>> getUpcomingBookings(String nurseEmail) async {
    try {
      final bookings = await MongoDatabase.patientNurseBookingsCollection?.find(
          where.eq('nurseEmail', nurseEmail)
              .ne('status', 'Completed')
              .ne('status', 'Cancelled')
              .sortBy('bookingDate', descending: false)
      ).toList();

      return bookings ?? [];
    } catch (e, stackTrace) {
      _logger.e('Error fetching upcoming bookings', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Get past bookings (status completed or cancelled)
  Future<List<Map<String, dynamic>>> getPastBookings(String nurseEmail) async {
    try {
      final bookings = await MongoDatabase.patientNurseBookingsCollection?.find(
          where.eq('nurseEmail', nurseEmail)
              .or([
            where.eq('status', 'Completed'),
            where.eq('status', 'Cancelled'),
          ] as SelectorBuilder)
              .sortBy('bookingDate', descending: true)
      ).toList();

      return bookings ?? [];
    } catch (e, stackTrace) {
      _logger.e('Error fetching past bookings', error: e, stackTrace: stackTrace);
      return [];
    }
  }
}