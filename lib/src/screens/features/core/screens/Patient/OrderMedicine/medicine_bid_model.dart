import 'package:bson/bson.dart';

class MedicineBid {
  final String id;
  final String medicineEmail;
  final double price;
  final String status;
  final String requestId;
  final DateTime createdAt;
  String? nurseName;
  double? rating;

  MedicineBid({
    required this.id,
    required this.medicineEmail,
    required this.price,
    required this.status,
    required this.requestId,
    required this.createdAt,
    this.nurseName,
    this.rating,
  });

  factory MedicineBid.fromJson(Map<String, dynamic> json) => MedicineBid.fromMap(json);

  factory MedicineBid.fromMap(Map<String, dynamic> map) {
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

    return MedicineBid(
      id: id,
      requestId: requestId,
      medicineEmail: map['nurseEmail']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      status: map['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now().toUtc().add(Duration(hours:5)),
      nurseName: map['userName']?.toString(), // 👈 added support for userName
      rating: (map['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nurseEmail': medicineEmail,
    'price': price,
    'status': status,
    'requestId': requestId,
    'createdAt': createdAt.toIso8601String(),
    'nurseName': nurseName,
    'rating': rating,
  };
}
