import 'dart:convert';

class Bid {
  final String id;
  final String nurseEmail;
  final double price;
  final String status;
  final String requestId;
  final DateTime createdAt;
  String? nurseName;
  double? rating;

  Bid({
    required this.id,
    required this.nurseEmail,
    required this.price,
    required this.status,
    required this.requestId,
    required this.createdAt,
    this.nurseName,
    this.rating,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['_id'].toHexString(),
      nurseEmail: json['nurseEmail'],
      price: json['price'].toDouble(),
      status: json['status'],
      requestId: json['requestId'],
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }
}