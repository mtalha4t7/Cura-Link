import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logger/logger.dart';

import '../../../../../../mongodb/mongodb.dart';
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
    return await deleteBooking(bookingId);
  }
  Future<bool> completeBooking(String bookingId) async {
    return await updateBookingStatus(bookingId, 'Completed');
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
      final bookings = await MongoDatabase.patientNurseBookingsCollection?.find(
          where.eq('nurseEmail', nurseEmail)
              .ne('status', 'Completed')
              .ne('status', 'Cancelled')
              .sortBy('createdAt', descending: false)
      ).toList();

      return bookings?.map((booking) => _sanitizeBookingData(booking)).toList() ?? [];
    } catch (e, stackTrace) {
      _logger.e('Error fetching upcoming bookings', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPastBookings(String nurseEmail) async {
    try {
      final bookings = await MongoDatabase.patientNurseBookingsCollection?.find(
          where.eq('nurseEmail', nurseEmail)
              .or([
            where.eq('status', 'Completed'),
            where.eq('status', 'Cancelled'),
          ] as SelectorBuilder)
              .sortBy('createdAt', descending: true)
      ).toList();

      return bookings?.map((booking) => _sanitizeBookingData(booking)).toList() ?? [];
    } catch (e, stackTrace) {
      _logger.e('Error fetching past bookings', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Map<String, dynamic> _sanitizeBookingData(Map<String, dynamic> booking) {
    return {
      '_id': booking['_id'],
      'bookingId': booking['bookingId'] ?? '',
      'patientId': booking['patientId'] ?? '',
      'patientName': booking['patientName'] ?? 'Unknown Patient',
      'patientEmail': booking['patientEmail'] ?? '',
      'nurseEmail': booking['nurseEmail'] ?? '',
      'nurseName': booking['nurseName'] ?? 'Unknown Nurse',
      'serviceType': booking['serviceType'] ?? 'Nursing Service',
      'status': booking['status'] ?? 'Pending',
      'price': booking['price'] ?? 0.0,
      'createdAt': booking['createdAt'],
      'location': booking['location'] ?? 'No location provided',
      'duration': booking['duration'] ?? '1 hour',
    };
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
}