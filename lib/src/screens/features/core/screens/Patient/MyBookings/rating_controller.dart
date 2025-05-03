import 'package:bson/bson.dart';

import '../../../../../../mongodb/mongodb.dart';
import '../../../models/lab_Rating_Model.dart';

class RatingsController {
  static Future<void> submitRating({
    required String labEmail,
    required String userEmail,
    required double rating,
    required String review,
    required ObjectId bookingId,
  }) async {
    try {
      // Prevent duplicate rating
      final existing = await MongoDatabase.labRatingsCollection.findOne({
        'bookingId': bookingId,
        'userEmail': userEmail,
      });

      if (existing != null) {
        throw Exception('Rating already submitted for this booking.');
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
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }
}
