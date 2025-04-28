

import '../../../../../../mongodb/mongodb.dart'; // Make sure you import your MongoDB helper

class RatingsController {
  static Future<void> submitRating({
    required String labEmail,
    required String userEmail,
    required double rating,
    required String review,
  }) async {
    try {
      final ratingData = {
        'labEmail': labEmail,
        'userEmail': userEmail,
        'rating': rating,
        'review': review,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };
      // Insert into the "lab_ratings" collection
      await MongoDatabase.insertLabRating(ratingData);
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }
}
