import 'package:bson/bson.dart';

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

  factory Bid.fromJson(Map<String, dynamic> json) => Bid.fromMap(json);

  factory Bid.fromMap(Map<String, dynamic> map) {
    // Universal ID handling
    dynamic rawId = map['_id'];
    final String id = (rawId is ObjectId) ? rawId.toHexString() : rawId.toString();

    // Universal requestId handling
    dynamic rawRequestId = map['requestId'];
    final String requestId = (rawRequestId is ObjectId)
        ? rawRequestId.toHexString()
        : rawRequestId.toString();

    return Bid(
      id: id,
      requestId: requestId,
      nurseEmail: map['nurseEmail'].toString(),
      price: (map['price'] as num).toDouble(),
      status: map['status'].toString(),
      createdAt: DateTime.parse(map['createdAt'].toString()),
      rating: map['rating']?.toDouble(),
    );
  }
}