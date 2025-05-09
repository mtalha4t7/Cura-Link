import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logger/logger.dart';

import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../repository/user_repository/user_repository.dart';
import '../../../../authentication/models/chat_user_model.dart';

class MyOrdersScreenMedicineController extends GetxController {

  final Logger _logger = Logger();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var totalReceivedOrdersCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTotalMedicineOrdersCount();
  }
  // Fetch all received bookings count for current nurse (without filtering status)
  Future<void> fetchTotalMedicineOrdersCount() async {
    final userEmail = _auth.currentUser?.email;
    if (userEmail == null) {
      print('User not logged in.');
      totalReceivedOrdersCount.value = 0;
      return;
    }

    try {
      final bookings = await MongoDatabase.patientNurseBookingsCollection?.find(
        where.eq('patientEmail', userEmail.trim().toLowerCase())
            .sortBy('bookingDate', descending: false),
      ).toList();
      totalReceivedOrdersCount.value = bookings?.length ?? 0;
      print('Total bookings count fetched: ${totalReceivedOrdersCount.value}');
    } catch (e) {
      print('Error fetching total received bookings count: $e');
      totalReceivedOrdersCount.value = 0;
    }
  }



  /// Fetch all nurse bookings for a specific patient.
  Future<List<Map<String, dynamic>>> fetchOrderedMedicines(String patientEmail) async {
    try {
      debugPrint('Fetching all nurse bookings for: $patientEmail');
      final bookings = await MongoDatabase.medicalOrdersCollection?.find(
        where.eq('patientEmail', patientEmail.trim().toLowerCase())
            .sortBy('bookingDate', descending: false),
      ).toList();

      debugPrint('Fetched ${bookings?.length ?? 0} nurse bookings.');
      return bookings?.map((booking) => _sanitizeBookingData(booking)).toList() ?? [];
    } catch (e, stackTrace) {
      _logger.e('Error fetching nurse bookings', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Fetch user data from all user collections.
  Future<ChatUserModelMongoDB?> fetchUserData(String email) async {
    try {
      debugPrint('Fetching user data for: $email');
      final userData = await UserRepository.instance.getUserByEmailFromAllCollections(email);
      return userData != null ? ChatUserModelMongoDB.fromMap(userData) : null;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  /// Update booking status (generic).
  Future<bool> updateOrderStatus(dynamic bookingId, String newStatus) async {
    try {
      debugPrint('Updating booking [$bookingId] to status: $newStatus');

      final id = _parseObjectId(bookingId);
      final result = await MongoDatabase.medicalOrdersCollection?.updateOne(
        where.id(id),
        modify
            .set('status', newStatus)
            .set('updatedAt', DateTime.now()),
      );

      debugPrint('Update result: ${result?.isSuccess}');
      return result?.isSuccess ?? false;
    } catch (e, stackTrace) {
      _logger.e('Error updating booking status', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  Future<bool> deleteOrder(dynamic bookingId) async {
    try {
      debugPrint('Deleting booking [$bookingId]');

      final id = _parseObjectId(bookingId);
      final result = await MongoDatabase.medicalOrdersCollection?.deleteOne(
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
  Future<bool> cancelOrder(dynamic bookingId) async {
    return await deleteOrder(bookingId);
  }

  /// Complete a booking
  Future<bool> completeOrder(dynamic bookingId) async {
    return await updateOrderStatus(bookingId, 'Completed');
  }

  /// Get detailed info about a specific booking
  Future<Map<String, dynamic>?> getOrderDetails(dynamic bookingId) async {
    try {
      debugPrint('Getting booking details for: $bookingId');
      final id = _parseObjectId(bookingId);
      final booking = await MongoDatabase.medicalOrdersCollection?.findOne(where.id(id));
      if (booking != null) {
        debugPrint('Booking found: ${booking['_id']}');
        return _sanitizeBookingData(booking);
      } else {
        debugPrint('No booking found with ID: $bookingId');
        return null;
      }
    } catch (e, stackTrace) {
      _logger.e('Error getting booking details', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get upcoming bookings (not completed or cancelled)
  Future<List<Map<String, dynamic>>> getUpcomingOrders(String patientEmail) async {
    try {
      debugPrint('Fetching upcoming bookings for: $patientEmail');
      final bookings = await MongoDatabase.medicalOrdersCollection?.find(
        where.eq('patientEmail', patientEmail.trim().toLowerCase())
            .ne('status', 'Completed')
            .ne('status', 'Cancelled')
            .sortBy('bookingDate', descending: false),
      ).toList();

      debugPrint('Upcoming bookings count: ${bookings?.length ?? 0}');
      return bookings?.map((booking) => _sanitizeBookingData(booking)).toList() ?? [];
    } catch (e, stackTrace) {
      _logger.e('Error fetching upcoming bookings', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get past bookings (completed or cancelled)
  Future<List<Map<String, dynamic>>> getPastOrders(String patientEmail) async {
    try {
      debugPrint('Fetching past bookings for: $patientEmail');
      final bookings = await MongoDatabase.patientNurseBookingsCollection?.find(
        where.eq('patientEmail', patientEmail.trim().toLowerCase())
            .or([
          where.eq('status', 'Completed'),
          where.eq('status', 'Cancelled'),
        ] as SelectorBuilder)
            .sortBy('bookingDate', descending: true),
      ).toList();

      debugPrint('Past bookings count: ${bookings?.length ?? 0}');
      return bookings?.map((booking) => _sanitizeBookingData(booking)).toList() ?? [];
    } catch (e, stackTrace) {
      _logger.e('Error fetching past bookings', error: e, stackTrace: stackTrace);
      return [];
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

  /// Sanitize and format the booking data
  Map<String, dynamic> _sanitizeBookingData(Map<String, dynamic> booking) {
    return {
      '_id': booking['_id'],
      'bookingId': booking['bookingId'] ?? '',
      'patientId': booking['patientId'] ?? '',
      'patientName': booking['patientName'] ?? 'Unknown Patient',
      'patientEmail': booking['patientEmail']?.toString().toLowerCase() ?? '',
      'nurseEmail': booking['storeEmail']?.toString().toLowerCase() ?? '',
      'nurseName': booking['StoreName'] ?? 'Unknown Store',
      'status': (booking['status'] ?? 'Pending').toString(),
      'price': _parsePrice(booking['price']),
      'bookingDate': booking['bookingDate']?.toString() ?? '',
      'duration': booking['duration'] ?? '1 hour',
      'address': booking['address'] ?? 'No address provided',
      'location': booking['location'] ?? '',
      'createdAt': booking['createdAt']?.toString() ?? '',
      'bids': booking['bids'] ?? [],
    };
  }

  /// Parse price from different formats
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
}