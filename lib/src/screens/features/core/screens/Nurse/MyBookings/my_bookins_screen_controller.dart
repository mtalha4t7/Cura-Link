import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logger/logger.dart';

import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../notification_handler/send_notification.dart';
import '../../../../../../repository/user_repository/user_repository.dart';
import '../../../../authentication/models/chat_user_model.dart';

class MyBookingsNurseController {
  final Logger _logger = Logger();

  Future<List<Map<String, dynamic>>> fetchNurseBookings(String nurseEmail) async {
    try {
      final bookings = await MongoDatabase.patientNurseBookingsCollection?.find(
          where.eq('nurseEmail', nurseEmail)
              .sortBy('createdAt', descending: false)
      ).toList();

      return bookings?.map((booking) => _sanitizeBookingData(booking)).toList() ?? [];
    } catch (e, stackTrace) {
      _logger.e('Error fetching nurse bookings', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<ChatUserModelMongoDB?> fetchUserData(String email) async {
    try {
      final userData = await UserRepository.instance.getUserByEmailFromAllCollections(email);
      return userData != null ? ChatUserModelMongoDB.fromMap(userData) : null;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  Future<bool> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      final id = _parseObjectId(bookingId);

      final result = await MongoDatabase.patientNurseBookingsCollection?.updateOne(
        where.id(id),
        modify
            .set('status', newStatus)
            .set('updatedAt',  DateTime.now().toUtc().add(Duration(hours:5))),
      );

      debugPrint('Update result: ${result?.isSuccess}, matched: ${result?.nMatched}, modified: ${result?.nModified}');
      return result?.isSuccess ?? false;
    } catch (e, stackTrace) {
      _logger.e('Error updating booking status', error: e, stackTrace: stackTrace);
      return false;
    }
  }


  Future<bool> deleteBooking(dynamic bookingId) async {
    try {
      debugPrint('Deleting booking [$bookingId]');

      final id = _parseObjectId(bookingId);
      final result = await MongoDatabase.patientNurseBookingsCollection?.deleteOne(
        where.id(id),
      );

      debugPrint('Delete result: ${result?.isSuccess}');
      return result?.isSuccess ?? false;
    } catch (e, stackTrace) {
      _logger.e('Error deleting booking', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Cancel a booking
  Future<bool> cancelBooking(dynamic bookingId) async {
    final result = await deleteBooking(bookingId);

    if (result) {
      final patientDetails = await MongoDatabase.getPatientDetailsByBookingId(bookingId);

      if (patientDetails != null && patientDetails['deviceToken'] != null) {
        final token = patientDetails['deviceToken'].toString();
        final name = patientDetails['userName'] ?? 'Patient';

        await SendNotificationService.sendNotificationUsingApi(
          token: token,
          title: 'Booking Cancelled',
          body: 'Your booking has been cancelled by the nurse.',
          data: {
            'screen': 'PatientBookingsScreen',
          },
        );

        print("Notification sent to $name about cancellation.");
      }
    }

    return result;
  }

  Future<bool> completeBooking(String bookingId) async {
    final result = await updateBookingStatus(bookingId, 'Completed');

    if (result) {
      final patientDetails = await MongoDatabase.getPatientDetailsByBookingId(bookingId);

      if (patientDetails != null && patientDetails['deviceToken'] != null) {
        final token = patientDetails['deviceToken'].toString();
        final name = patientDetails['userName'] ?? 'Patient';

        await SendNotificationService.sendNotificationUsingApi(
          token: token,
          title: 'Booking Completed',
          body: 'Your service booking has been marked completed by the nurse.',
          data: {
            'screen': 'PatientBookingsScreen',
          },
        );

        print("Notification sent to $name about completion.");
      }
    }

    return result;
  }


  Future<Map<String, dynamic>?> getBookingDetails(String bookingId) async {
    try {
      final id = ObjectId.parse(bookingId);
      final booking = await MongoDatabase.patientNurseBookingsCollection?.findOne(where.id(id));
      return booking != null ? _sanitizeBookingData(booking) : null;
    } catch (e, stackTrace) {
      _logger.e('Error getting booking details', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingBookings(String nurseEmail) async {
    try {
      debugPrint('Fetching upcoming bookings for: $nurseEmail');
      final bookings = await MongoDatabase.patientNurseBookingsCollection?.find(
        where.eq('nurseEmail', nurseEmail.trim().toLowerCase())
            .ne('status', 'Completed')
            .ne('status', 'Cancelled')
            .sortBy('bookingDate', descending: false),
      ).toList();

      debugPrint('Raw booking data from DB: ${bookings?.toString()}'); // Add this line
      debugPrint('Upcoming bookings count: ${bookings?.length ?? 0}');

      final sanitized = bookings?.map((booking) => _sanitizeBookingData(booking)).toList() ?? [];
      debugPrint('Sanitized booking data: $sanitized'); // Add this line
      return sanitized;
    } catch (e, stackTrace) {
      _logger.e('Error fetching upcoming bookings', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get past bookings (completed or cancelled)

  Future<List<Map<String, dynamic>>> getPastBookings(String nurseEmail) async {
    try {
      debugPrint('Fetching past bookings for: $nurseEmail');

      final bookings = await MongoDatabase.patientNurseBookingsCollection?.find(
          where.eq('nurseEmail', nurseEmail.trim().toLowerCase())
              .ne('status', 'accepted')
              .ne('status', 'pending')

      ).toList();

      debugPrint('Raw past booking data from DB: ${bookings?.toString()}');
      debugPrint('Past bookings count: ${bookings?.length ?? 0}');

      final sanitized = bookings?.map((booking) => _sanitizeBookingData(booking)).toList() ?? [];
      debugPrint('Sanitized past booking data: $sanitized');

      return sanitized;
    } catch (e, stackTrace) {
      _logger.e('Error fetching past bookings', error: e, stackTrace: stackTrace);
      return [];
    }
  }



  Map<String, dynamic> _sanitizeBookingData(Map<String, dynamic> booking) {
    return {
      '_id': booking['_id'],
      'bookingId': booking['bookingId']?.toString() ?? '', // Ensure string conversion
      'patientId': booking['patientId']?.toString() ?? '',
      'patientName': booking['patientName']?.toString() ?? 'Unknown Patient',
      'patientEmail': booking['patientEmail']?.toString().toLowerCase() ?? '',
      'nurseEmail': booking['nurseEmail']?.toString().toLowerCase() ?? '',
      'nurseName': booking['nurseName']?.toString() ?? 'Unknown Nurse',
      'serviceName': booking['serviceName']?.toString() ?? 'Nursing Service', // Ensure string
      'status': (booking['status']?.toString() ?? 'Pending').toString(),
      'price': _parsePrice(booking['price']),
      'bookingDate': booking['bookingDate']?.toString() ?? '',
      'duration': booking['duration']?.toString() ?? '1 hour',
      'address': booking['address']?.toString() ?? 'No address provided',
      'location': booking['location'] ?? {},
      'createdAt': booking['createdAt']?.toString() ?? '',
      'bids': booking['bids'] is List ? booking['bids'] : [],
    };
  }
  double _parsePrice(dynamic price) {
    try {
      if (price is num) return price.toDouble();
      if (price is Map && price['\$numberDouble'] != null) {
        return double.parse(price['\$numberDouble']);
      }
      if (price is String) return double.tryParse(price) ?? 0.0;
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }
  /// Parse different ObjectId formats
  ObjectId _parseObjectId(dynamic id) {
    try {
      if (id is ObjectId) return id;
      if (id is String) {
        // Remove any quotes or ObjectId wrapper if present
        String cleanedId = id.replaceAll('ObjectId("', '').replaceAll('")', '').trim();

        // Check if the string is a valid 24-character hex string
        if (cleanedId.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(cleanedId)) {
          return ObjectId.fromHexString(cleanedId);
        }
      }
      throw Exception('Invalid ID format: $id (${id.runtimeType})');
    } catch (e, stackTrace) {
      _logger.e('Error parsing ObjectId', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  ObjectId _parseObjectIdd(dynamic bookingId) {
    if (bookingId is ObjectId) {
      return bookingId;
    }

    final idString = bookingId.toString();
    final regex = RegExp(r'ObjectId\("([a-fA-F0-9]{24})"\)');
    final match = regex.firstMatch(idString);

    if (match != null) {
      return ObjectId.parse(match.group(1)!);
    }

    if (idString.length == 24 && RegExp(r'^[a-fA-F0-9]+$').hasMatch(idString)) {
      return ObjectId.parse(idString);
    }

    throw ArgumentError('Invalid bookingId format: $bookingId');
  }

}