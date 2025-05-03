import 'package:bson/bson.dart';

class LabRating {
  ObjectId? id;
  final String labEmail;
  final String userEmail;
  final double rating;
  final String review;
  final DateTime createdAt;
  final ObjectId bookingId; // NEW

  LabRating({
    this.id,
    required this.labEmail,
    required this.userEmail,
    required this.rating,
    required this.review,
    required this.createdAt,
    required this.bookingId, // NEW
  });

  factory LabRating.fromJson(Map<String, dynamic> json) {
    return LabRating(
      id: json['_id'],
      labEmail: json['labEmail'] ?? '',
      userEmail: json['userEmail'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      review: json['review'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      bookingId: json['bookingId'], // NEW
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'labEmail': labEmail,
      'userEmail': userEmail,
      'rating': rating,
      'review': review,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'bookingId': bookingId, // NEW
    };
    if (id != null) {
      map['_id'] = id!;
    }
    return map;
  }
}
