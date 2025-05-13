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
  final Map<String, bool> _hasRatingCache = {};

  @override
  void onInit() {
    super.onInit();
    fetchTotalMedicineOrdersCount();
  }


  Future<bool> submitRating({
    required String bookingId,
    required String storeEmail,
    required int rating,
    required String review,
  }) async {
    try {
      final userEmail = _auth.currentUser?.email;
      if (userEmail == null) return false;

      final existingRating = await MongoDatabase.medicalStoreRatingCollection?.findOne({
        'bookingId': bookingId,
        'patientEmail': userEmail.toLowerCase(),
      });

      if (existingRating != null) return false;

      final ratingDoc = {
        'storeEmail': storeEmail.toLowerCase(),
        'patientEmail': userEmail.toLowerCase(),
        'rating': rating,
        'review': review,
        'bookingId': bookingId,
        'createdAt':  DateTime.now().toUtc().add(Duration(hours:5)),
      };

      final insertResult = await MongoDatabase.medicalStoreRatingCollection?.insertOne(ratingDoc);

      if (insertResult?.isSuccess ?? false) {
        await MongoDatabase.completedOrdersCollection?.updateOne(
          where.id(_parseObjectId(bookingId)),
          modify.set('rated', true),
        );
        _hasRatingCache[bookingId] = true;
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _logger.e('Error submitting rating', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> hasRatingForBooking(String bookingId) async {
    if (_hasRatingCache.containsKey(bookingId)) {
      return _hasRatingCache[bookingId]!;
    }

    try {
      final rating = await MongoDatabase.medicalStoreRatingCollection?.findOne(
          where.eq('bookingId', bookingId)
      );
      final hasRating = rating != null;
      _hasRatingCache[bookingId] = hasRating;
      return hasRating;
    } catch (e) {
      return false;
    }
  }


  Future<void> fetchTotalMedicineOrdersCount() async {
    final userEmail = _auth.currentUser?.email;
    if (userEmail == null) {
      print('User not logged in.');
      totalReceivedOrdersCount.value = 0;
      return;
    }

    try {
      final bookings = await MongoDatabase.medicalOrdersCollection?.find(
        where.eq('patientEmail', userEmail.trim().toLowerCase()),
      ).toList();
      totalReceivedOrdersCount.value = bookings?.length ?? 0;
    } catch (e) {
      print('Error fetching total medicine orders count: $e');
      totalReceivedOrdersCount.value = 0;
    }
  }

  Future<List<Map<String, dynamic>>> fetchOrderedMedicines(String patientEmail) async {
    try {
      final bookings = await MongoDatabase.medicalOrdersCollection?.find(
        where.eq('patientEmail', patientEmail.trim().toLowerCase()),
      ).toList();
      return bookings?.map((booking) => _sanitizeBookingData(booking)).toList() ?? [];
    } catch (e, stackTrace) {
      _logger.e('Error fetching medicine orders', error: e, stackTrace: stackTrace);
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

  Future<bool> updateOrderStatus(dynamic bookingId, String newStatus, String paymentMethod) async {
    try {
      final id = _parseObjectId(bookingId);

      // First get the current order data
      final order = await MongoDatabase.medicalOrdersCollection?.findOne(where.id(id));
      if (order == null) {
        _logger.e('Order not found with ID: $bookingId');
        return false;
      }

      // Update the order with new status and payment method
      final updateResult = await MongoDatabase.medicalOrdersCollection?.updateOne(
        where.id(id),
        modify
            .set('status', newStatus)
            .set('paymentMethod', paymentMethod)
            .set('updatedAt',  DateTime.now().toUtc().add(Duration(hours:5))),
      );

      if (!(updateResult?.isSuccess ?? false)) {
        return false;
      }

      // If status is 'completed' or 'delivered', move to completed collection
      if (newStatus.toLowerCase() == 'completed' || newStatus.toLowerCase() == 'delivered') {
        // Add additional completion data
        final completedOrder = {
          ...order,
          'completionDate':  DateTime.now().toUtc().add(Duration(hours:5)),
          'status': newStatus,
          'paymentMethod': paymentMethod,
          'updatedAt': DateTime.now().toUtc().add(Duration(hours:5)),
        };

        // Insert into completed orders collection
        final insertResult = await MongoDatabase.completedOrdersCollection?.insertOne(completedOrder);

        if (insertResult?.isSuccess ?? false) {
          // Only delete from original collection if insert was successful
          final deleteResult = await MongoDatabase.medicalOrdersCollection?.deleteOne(where.id(id));
          return deleteResult?.isSuccess ?? false;
        }
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      _logger.e('Error updating order status', error: e, stackTrace: stackTrace);
      return false;
    }
  }


  Future<bool> deleteOrder(dynamic bookingId) async {
    try {
      final id = _parseObjectId(bookingId);
      final result = await MongoDatabase.medicalOrdersCollection?.deleteOne(
        where.id(id),
      );
      return result?.isSuccess ?? false;
    } catch (e, stackTrace) {
      _logger.e('Error deleting order', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> cancelOrder(dynamic bookingId) async {
    return await deleteOrder(bookingId);
  }

  Future<bool> completeOrder(dynamic bookingId,String paymentMethod) async {
    return await updateOrderStatus(bookingId, 'Completed',paymentMethod);
  }

  Future<Map<String, dynamic>?> getOrderDetails(dynamic bookingId) async {
    try {
      final id = _parseObjectId(bookingId);
      final booking = await MongoDatabase.medicalOrdersCollection?.findOne(where.id(id));
      return booking != null ? _sanitizeBookingData(booking) : null;
    } catch (e, stackTrace) {
      _logger.e('Error getting order details', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingOrders(String patientEmail) async {
    try {
      final bookings = await MongoDatabase.medicalOrdersCollection?.find(
        where.eq('patientEmail', patientEmail.trim().toLowerCase())
            .ne('status', 'Completed')
            .ne('status', 'Cancelled'),
      ).toList();
      return bookings?.map((booking) => _sanitizeBookingData(booking)).toList() ?? [];
    } catch (e, stackTrace) {
      _logger.e('Error fetching upcoming orders', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPastOrders(String patientEmail) async {
    try {
      final bookings = await MongoDatabase.completedOrdersCollection?.find(
        where.eq('patientEmail', patientEmail.trim().toLowerCase())
            .ne('status', 'completed')
            .ne('status', 'Cancelled'),
      ).toList();
      return bookings?.map((booking) => _sanitizeBookingData(booking)).toList() ?? [];
    } catch (e, stackTrace) {
      _logger.e('Error fetching upcoming orders', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  ObjectId _parseObjectId(dynamic id) {
    try {
      if (id is ObjectId) return id;
      if (id is String) {
        String cleanedId = id.replaceAll('ObjectId("', '').replaceAll('")', '').trim();
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

  Map<String, dynamic> _sanitizeBookingData(Map<String, dynamic> booking) {
    return {
      '_id': booking['_id'],
      'requestId': booking['requestId'] ?? '',
      'bidId': booking['bidId'] ?? '',
      'patientEmail': booking['patientEmail']?.toString().toLowerCase() ?? '',
      'storeName': booking['storeName'] ?? 'Unknown Store',
      'storeEmail': booking['storeEmail']?.toString().toLowerCase() ?? '',
      'finalAmount': _parsePrice(booking['finalAmount']),
      'status': (booking['status'] ?? 'Pending').toString(),
      'distance': booking['distance'] ?? '0m',
      'createdAt': _parseDate(booking['createdAt']),
      'expectedDeliveryTime': _parseDate(booking['expectedDeliveryTime']),
      'deliveryTime': booking['deliveryTime'] ?? '',
      'medicines': booking['medicines'],
      'prescriptionDetails':booking['prescriptionDetails']
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

  String _parseDate(dynamic date) {
    try {
      if (date is String) return date;
      if (date is Map && date['\$date'] != null) {
        final milliseconds = date['\$date']['\$numberLong'];
        return DateTime.fromMillisecondsSinceEpoch(int.parse(milliseconds)).toString();
      }
      return date?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }
}