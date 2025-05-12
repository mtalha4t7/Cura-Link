import 'package:bson/bson.dart';
import 'package:flutter/cupertino.dart';
import '../../../../../../mongodb/mongodb.dart';
import '../../../models/lab_Rating_Model.dart';

class RatingsController {
  static Future<bool> submitRating({
    required String labEmail,
    required String userEmail,
    required double rating,
    required String review,
    required ObjectId bookingId,
  }) async {
    try {
      // Check if rating already exists
      final existing = await MongoDatabase.labRatingsCollection.findOne({
        'bookingId': bookingId,
      });

      if (existing != null) {
        return false; // Rating already exists
      }

      final labRating = LabRating(
        labEmail: labEmail,
        userEmail: userEmail,
        rating: rating,
        review: review,
        createdAt: DateTime.now(),
        bookingId: bookingId,
      );

      await MongoDatabase.insertLabRating(labRating.toJson());
      return true; // Success
    } catch (e) {
      debugPrint('Failed to submit rating: $e');
      return false; // Failure
    }
  }

  static Future<bool> hasRatingForBooking(ObjectId bookingId) async {
    try {
      final existing = await MongoDatabase.labRatingsCollection.findOne({
        'bookingId': bookingId,
      });
      return existing != null;
    } catch (e) {
      debugPrint('Error checking rating: $e');
      return false;
    }
  }
}
