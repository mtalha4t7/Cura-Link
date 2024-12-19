import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../constants/text_strings.dart'; // Ensure this path is correct
import 'package:logger/logger.dart';

// Initialize a logger for better logging
final logger = Logger();

class MongoDatabase {
  static Db? _db;
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

      logger.i('Connected to MongoDB database successfully');
    } catch (e, stackTrace) {
      logger.e('Error connecting to MongoDB', error: e, stackTrace: stackTrace);
      rethrow; // Rethrow the exception if needed
    }
  }

  // Close the MongoDB connection
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _userCollection = null;
      logger.i('MongoDB connection closed');
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
  static Future<void> insertUser (Map<String, dynamic> user) async {
    try {
      // Validate the input
      if (user.isEmpty || !user.containsKey('userEmail')) {
        throw Exception('Invalid user data: Missing required fields');
      }

      // Check for duplicate email
      final existingUser  = await userCollection.findOne({'userEmail': user['userEmail']});
      if (existingUser  != null) {
        throw Exception('User  with the same email already exists');
      }

      // Insert the user
      await userCollection.insertOne(user);
      logger.i('User  inserted successfully');
    } catch (e, stackTrace) {
      logger.e('Error inserting user', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Function to find a user by email
  static Future<Map<String, dynamic>?> findUser ({required String email}) async {
    try {
      if (email.isEmpty) {
        throw Exception('Email cannot be empty');
      }

      var user = await userCollection.findOne({'userEmail': email});
      logger.i(user != null ? 'User  found' : 'User  not found');
      return user;
    } catch (e, stackTrace) {
      logger.e('Error finding user', error: e, stackTrace: stackTrace);
      return null;
    }
  }


  // Function to update user details (e.g., after login)
  static Future<void> updateUser (Map<String, dynamic> updatedUser ) async {
    try {
      var userId = updatedUser ['userId'];
      if (userId == null) {
        throw Exception('User  ID is required for updating');
      }

      // Create a ModifierBuilder
      final modifier = modify..set('lastLogin', DateTime.now());

      // Set each field in updatedUser
      updatedUser .forEach((key, value) {
        if (key != '_id') { // Avoid setting the _id field
          modifier.set(key, value);
        }
      });

      // Update the user document
      await userCollection.updateOne(
        where.eq('_id', userId),
        modifier,
      );

      logger.i('User  updated successfully');
    } catch (e, stackTrace) {
      logger.e('Error updating user', error: e, stackTrace: stackTrace);
      rethrow; // Rethrow the exception if needed
    }
  }

  // Function to create an index on the collection
  static Future<void> createIndexes() async {
    try {
      await userCollection.createIndex(keys: {'userEmail ': 1}, unique: true);
      logger.i('Indexes created successfully');
    } catch (e, stackTrace) {
      logger.e('Error creating indexes', error: e, stackTrace: stackTrace);
      rethrow; // Rethrow the exception if needed
    }
  }
}