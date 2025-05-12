import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logger/logger.dart';

import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../repository/user_repository/user_repository.dart';
import '../../../../authentication/models/chat_user_model.dart';

class PendingAndCompletedOrdersController extends GetxController {
  final Logger _logger = Logger();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var totalPendingOrdersCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTotalPendingOrdersCount();
  }

  Future<void> fetchTotalPendingOrdersCount() async {
    final storeEmail = _auth.currentUser?.email;
    if (storeEmail == null) {
      print('Store not logged in.');
      totalPendingOrdersCount.value = 0;
      return;
    }

    try {
      final orders = await MongoDatabase.medicalOrdersCollection?.find(
        where.eq('storeEmail', storeEmail.trim().toLowerCase())
            .eq('status', 'Pending'),
      ).toList();
      totalPendingOrdersCount.value = orders?.length ?? 0;
    } catch (e) {
      print('Error fetching pending orders count: $e');
      totalPendingOrdersCount.value = 0;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingOrders(String storeEmail) async {
    try {
      final orders = await MongoDatabase.medicalOrdersCollection?.find(
        where.eq('storeEmail', storeEmail.trim().toLowerCase())
            .eq('status', 'preparing'),
      ).toList();
      return orders?.map((order) => _sanitizeOrderData(order)).toList() ?? [];
    } catch (e, stackTrace) {
      _logger.e('Error fetching pending orders', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPreparingOrders(String storeEmail) async {
    try {
      final orders = await MongoDatabase.medicalOrdersCollection?.find(
        where.eq('storeEmail', storeEmail.trim().toLowerCase())
            .eq('status', 'preparing'),
      ).toList();
      return orders?.map((order) => _sanitizeOrderData(order)).toList() ?? [];
    } catch (e, stackTrace) {
      _logger.e('Error fetching preparing orders', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final id = _parseObjectId(orderId);
      final result = await MongoDatabase.medicalOrdersCollection?.updateOne(
        where.id(id),
        modify.set('status', newStatus),
      );
      return result?.isSuccess ?? false;
    } catch (e, stackTrace) {
      _logger.e('Error updating order status', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> acceptOrder(String orderId) async {
    return await updateOrderStatus(orderId, 'Preparing');
  }

  Future<bool> completeOrder(String orderId) async {
    return await updateOrderStatus(orderId, 'Completed');
  }

  Future<bool> cancelOrder(String orderId) async {
    return await updateOrderStatus(orderId, 'Cancelled');
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

  Map<String, dynamic> _sanitizeOrderData(Map<String, dynamic> order) {
    return {
      '_id': order['_id'],
      'requestId': order['requestId'] ?? '',
      'patientEmail': order['patientEmail'] ?? '',
      'patientName': order['patientName'] ?? 'Unknown Patient',
      'storeName': order['storeName'] ?? 'Unknown Store',
      'storeEmail': order['storeEmail'] ?? '',
      'finalAmount': _parsePrice(order['finalAmount']),
      'status': order['status'] ?? 'Pending',
      'distance': order['distance'] ?? '0m',
      'createdAt': _parseDate(order['createdAt']),
      'expectedDeliveryTime': _parseDate(order['expectedDeliveryTime']),
      'deliveryTime': order['deliveryTime'] ?? '',
      'patientLocation': order['patientLocation'] ?? {},
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
}