

import '../../../../../../mongodb/mongodb.dart';
import '../../../models/lab_Rating_Model.dart'; // adjust path if needed

class RatingsController {
  static Future<void> submitRating({
    required String labEmail,
    required String userEmail,
    required double rating,
    required String review,
  }) async {
    try {
      final labRating = LabRating(
        labEmail: labEmail,
        userEmail: userEmail,
        rating: rating,
        review: review,
        createdAt: DateTime.now(),
      );

      await MongoDatabase.insertLabRating(labRating.toJson());
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }
}
