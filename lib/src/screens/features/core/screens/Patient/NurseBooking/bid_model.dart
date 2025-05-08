import 'package:bson/bson.dart';

class Bid {
  final String id;
  final String nurseEmail;
  final double price;
  final String status;
  final String requestId;
  final DateTime createdAt;
  final String? serviceName; // 👈 Added serviceName
  String? nurseName;
  double? rating;

  Bid({
    required this.id,
    required this.nurseEmail,
    required this.price,
    required this.status,
    required this.requestId,
    required this.createdAt,
    this.serviceName, // 👈 Include in constructor
    this.nurseName,
    this.rating,
  });

  factory Bid.fromJson(Map<String, dynamic> json) => Bid.fromMap(json);

  factory Bid.fromMap(Map<String, dynamic> map) {
    dynamic rawId = map['_id'];
    final String id = (rawId is ObjectId)
        ? rawId.toHexString()
        : rawId?.toString() ?? '';

    dynamic rawRequestId = map['requestId'];
    final String requestId = (rawRequestId is ObjectId)
        ? rawRequestId.toHexString()
        : rawRequestId?.toString() ?? '';

    return Bid(
      id: id,
      requestId: requestId,
      nurseEmail: map['nurseEmail']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      status: map['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      serviceName: map['serviceName']?.toString(), // 👈 Parse serviceName
      nurseName: map['userName']?.toString(),
      rating: (map['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nurseEmail': nurseEmail,
    'price': price,
    'status': status,
    'requestId': requestId,
    'createdAt': createdAt.toIso8601String(),
    'serviceName': serviceName, // 👈 Include in JSON
    'nurseName': nurseName,
    'rating': rating,
  };
}
