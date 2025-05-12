import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logger/logger.dart';

import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../repository/user_repository/user_repository.dart';
import '../../../../authentication/models/chat_user_model.dart';

class MyBookedNursesController extends GetxController {
  final Logger _logger = Logger();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var totalReceivedBookingsCount = 0.obs;
  final Map<String, bool> _hasRatingCache = {};

  @override
  void onInit() {
    super.onInit();
    fetchTotalReceivedBookingsCount();
  }

  Future<void> fetchTotalReceivedBookingsCount() async {
    final userEmail = _auth.currentUser?.email;
    if (userEmail == null) {
      print('User not logged in.');
      totalReceivedBookingsCount.value = 0;
      return;
    }

    try {
      final bookings = await MongoDatabase.patientNurseBookingsCollection?.find(
        where.eq('patientEmail', userEmail.trim().toLowerCase())
            .ne('status', 'Completed')
            .ne('status', 'Cancelled')
            .sortBy('bookingDate', descending: false),
      ).toList();
      totalReceivedBookingsCount.value = bookings?.length ?? 0;
    } catch (e) {
      print('Error fetching total received bookings count: $e');
      totalReceivedBookingsCount.value = 0;
    }
  }

  Future<List<Map<String, dynamic>>> fetchNurseBookings(String patientEmail) async {
    try {
      final bookings = await MongoDatabase.patientNurseBookingsCollection?.find(
        where.eq('patientEmail', patientEmail.trim().toLowerCase())
            .sortBy('bookingDate', descending: false),
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

  Future<bool> updateBookingStatus(dynamic bookingId, String newStatus) async {
    try {
      final id = _parseObjectId(bookingId);
      final result = await MongoDatabase.patientNurseBookingsCollection?.updateOne(
        where.id(id),
        modify.set('status', newStatus).set('updatedAt', DateTime.now()),
      );
      return result?.isSuccess ?? false;
    } catch (e, stackTrace) {
      _logger.e('Error updating booking status', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> hasRatingForBooking(String bookingId) async {
    if (_hasRatingCache.containsKey(bookingId)) {
      return _hasRatingCache[bookingId]!;
    }

    try {
      final rating = await MongoDatabase.nurseRatingCollection?.findOne(
          where.eq('bookingId', bookingId)
      );
      final hasRating = rating != null;
      _hasRatingCache[bookingId] = hasRating;
      return hasRating;
    } catch (e) {
      debugPrint('Error checking rating: $e');
      return false;
    }
  }

  Future<bool> submitRating({
    required String bookingId,
    required String nurseEmail,
    required String userEmail,
    required double rating,
    required String review,
  }) async {
    try {
      final alreadyRated = await hasRatingForBooking(bookingId);
      if (alreadyRated) return false;

      final ratingDoc = {
        'nurseEmail': nurseEmail.trim().toLowerCase(),
        'userEmail': userEmail.trim().toLowerCase(),
        'rating': rating,
        'review': review,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'bookingId': bookingId,
      };

      final result = await MongoDatabase.nurseRatingCollection?.insertOne(ratingDoc);
      if (result?.isSuccess == true) {
        _hasRatingCache[bookingId] = true;
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _logger.e('Error submitting rating', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> deleteBooking(dynamic bookingId) async {
    try {
      final id = _parseObjectId(bookingId);
      final result = await MongoDatabase.patientNurseBookingsCollection?.deleteOne(
        where.id(id),
      );
      return result?.isSuccess ?? false;
    } catch (e, stackTrace) {
      _logger.e('Error deleting booking', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> cancelBooking(dynamic bookingId) async => await deleteBooking(bookingId);
  Future<bool> completeBooking(dynamic bookingId) async => await updateBookingStatus(bookingId, 'Completed');

  Future<Map<String, dynamic>?> getBookingDetails(dynamic bookingId) async {
    try {
      final id = _parseObjectId(bookingId);
      final booking = await MongoDatabase.patientNurseBookingsCollection?.findOne(where.id(id));
      return booking != null ? _sanitizeBookingData(booking) : null;
    } catch (e, stackTrace) {
      _logger.e('Error getting booking details', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingBookings(String patientEmail) async {
    try {
      final bookings = await MongoDatabase.patientNurseBookingsCollection?.find(
        where.eq('patientEmail', patientEmail.trim().toLowerCase())
            .ne('status', 'Completed')
            .ne('status', 'Cancelled')
            .sortBy('bookingDate', descending: false),
      ).toList();
      return bookings?.map((booking) => _sanitizeBookingData(booking)).toList() ?? [];
    } catch (e, stackTrace) {
      _logger.e('Error fetching upcoming bookings', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPastBookings(String patientEmail) async {
    try {
      final bookings = await MongoDatabase.patientNurseBookingsCollection?.find(
        where.eq('patientEmail', patientEmail.trim().toLowerCase())
            .oneFrom('status', ['Completed', 'Cancelled'])
            .sortBy('createdAt', descending: true),
      ).toList();
      return bookings?.map((booking) => _sanitizeBookingData(booking)).toList() ?? [];
    } catch (e, stackTrace) {
      _logger.e('Error fetching past bookings', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  ObjectId _parseObjectId(dynamic id) {
    if (id is ObjectId) return id;
    if (id is String) {
      final cleanedId = id.replaceAll('ObjectId("', '').replaceAll('")', '').trim();
      if (cleanedId.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(cleanedId)) {
        return ObjectId.fromHexString(cleanedId);
      }
    }
    throw Exception('Invalid ID format: $id');
  }

  Map<String, dynamic> _sanitizeBookingData(Map<String, dynamic> booking) {
    return {
      '_id': booking['_id'],
      'bookingId': booking['bookingId']?.toString() ?? '',
      'patientId': booking['patientId']?.toString() ?? '',
      'patientName': booking['patientName']?.toString() ?? 'Unknown Patient',
      'patientEmail': booking['patientEmail']?.toString().toLowerCase() ?? '',
      'nurseEmail': booking['nurseEmail']?.toString().toLowerCase() ?? '',
      'nurseName': booking['nurseName']?.toString() ?? 'Unknown Nurse',
      'serviceName': booking['serviceName']?.toString() ?? 'Nursing Service',
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
}