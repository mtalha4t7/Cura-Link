import 'package:mongo_dart/mongo_dart.dart';

class LabRating {
  ObjectId? id;          // MongoDB _id field (optional for new ratings)
  final String labEmail; // Email of the lab
  final String userEmail; // Email of the user who gave the rating
  final double rating;    // Rating value (e.g., 4.5)
  final String review;    // Review text
  final DateTime createdAt; // Timestamp as DateTime (easy to work with)

  LabRating({
    this.id,
    required this.labEmail,
    required this.userEmail,
    required this.rating,
    required this.review,
    required this.createdAt,
  });

  /// Factory constructor to create a LabRating object from a Map (MongoDB document)
  factory LabRating.fromJson(Map<String, dynamic> json) {
    return LabRating(
      id: json['_id'],
      labEmail: json['labEmail'] ?? '',
      userEmail: json['userEmail'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      review: json['review'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  /// Convert a LabRating object to a Map (for inserting into MongoDB)
  Map<String, dynamic> toJson() {
    final map = {
      'labEmail': labEmail,
      'userEmail': userEmail,
      'rating': rating,
      'review': review,
      'createdAt': createdAt.millisecondsSinceEpoch, // Save as int (Mongo-friendly)
    };
    if (id != null) {
      map['_id'] = id!;
    }
    return map;
  }
}
