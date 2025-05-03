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
    // Universal _id handling
    dynamic rawId = map['_id'];
    final String id = (rawId is ObjectId)
        ? rawId.toHexString()
        : rawId?.toString() ?? '';

    // Universal requestId handling
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
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      nurseName: map['userName']?.toString(), // 👈 added support for userName
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
    'nurseName': nurseName,
    'rating': rating,
  };
}
