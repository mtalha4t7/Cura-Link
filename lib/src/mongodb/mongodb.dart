import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../constants/text_strings.dart';

class MongoDatabase {
  // MongoDB connection instance
  static Db? _db;
  // MongoDB collection instance
  static DbCollection? _userCollection;

  // Connect to MongoDB and initialize the collection
  static Future<void> connect() async {
    try {
      // Connect to the MongoDB database
      _db = await Db.create(MONGO_URL);
      await _db!.open();

      // Access the user collection from the database
      _userCollection = _db!.collection(COLLECTION_NAME);

      // Optional: Use inspect to debug the database connection
      inspect(_db);

      if (kDebugMode) {
        print('Connected to MongoDB database successfully');
      }
    } catch (e) {
      // Handle errors if the connection fails
      if (kDebugMode) {
        print('Error connecting to MongoDB: $e');
      }
    }
  }

  // Getter for the MongoDB instance
  static Db get db {
    if (_db == null) {
      throw Exception('MongoDB connection is not initialized');
    }
    return _db!;
  }

  // Getter for the user collection
  static DbCollection get userCollection {
    if (_userCollection == null) {
      throw Exception('MongoDB collection is not initialized');
    }
    return _userCollection!;
  }

  // Function to insert a user document into the collection
  static Future<void> insertUser(Map<String, dynamic> user) async {
    try {
      await userCollection.insertOne(user);
      if (kDebugMode) {
        print('User inserted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting user: $e');
      }
    }
  }

  // Function to find a user by email and password
  static Future<Map<String, dynamic>?> findUser({
    required String email,
    required String password,
  }) async {
    try {
      var user = await userCollection.findOne({
        'email': email,
        'password': password,
      });
      return user;
    } catch (e) {
      if (kDebugMode) {
        print('Error finding user: $e');
      }
      return null;
    }
  }

  // Function to update user details (e.g., after login)
  static Future<void> updateUser(Map<String, dynamic> updatedUser) async {
    try {
      var userId = updatedUser['_id']; // Assuming the user document has '_id'
      await userCollection.updateOne(
        where.eq('_id', userId),
        modify.set('lastLogin', DateTime.now()),
      );
      if (kDebugMode) {
        print('User updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user: $e');
      }
    }
  }
}
