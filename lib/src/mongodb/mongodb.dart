import 'dart:developer';
import 'package:mongo_dart/mongo_dart.dart';
import '../constants/text_strings.dart';

class MongoDatabase {
  static Future<void> connect() async {
    try {
      // Connect to the MongoDB database
      var db = await Db.create(MONGO_URL);
      await db.open();

      // Use inspect to debug the database connection
      inspect(db);

      // Access the collection
      var collection = db.collection(COLLECTION_NAME);

      // Optional: Print a success message
      print('Connected to the database successfully');
    } catch (e) {
      // Handle errors if the connection fails
      print('Error connecting to the database: $e');
    }
  }
}
