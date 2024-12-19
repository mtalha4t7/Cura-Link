
import 'package:cura_link/src/mongodb/mongodb.dart';
import 'package:get/get.dart';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:image_picker/image_picker.dart';


class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();
  final ImagePicker _picker = ImagePicker();

  Future<void> uploadProfileImage(String email, String base64Image) async {
    try {
      print('Attempting to update profile image for: $email');
      print('Base64 Image Data: $base64Image');

      // Query to find the current profile
      final query = {'userEmail': email};
      print('Query: $query');  // Print query to ensure it's correct

      // Find the current profile
      final currentProfile = await MongoDatabase.userCollection.findOne(query);

      if (currentProfile == null) {
        print('No document found for email: $email');
        return; // Exit if no user found
      }

      print('Current Profile Image: ${currentProfile['profileImage']}');

      // Check if the new image is the same as the current one
      if (currentProfile['profileImage'] == base64Image) {
        print('New image is the same as the current one. No update needed.');
        return;  // Skip update if the image is the same
      }

      // Update the profile image
      final result = await MongoDatabase.userCollection.updateOne(
        query,
        modify.set('profileImage', base64Image),
      );

      print('Update Result - Matched: ${result.nMatched}, Modified: ${result.nModified}');

      if (result.nMatched == 0) {
        print('No document matched the given email.');
      } else if (result.nModified == 0) {
        print('The document was matched, but no modification was made (image might be the same).');
      } else {
        print('Profile image updated successfully.');
      }

      // Load the updated profile image (after update)
      final profileImageResult = await MongoDatabase.userCollection.findOne(query);
      if (profileImageResult != null) {
        print('Updated Profile Image: ${profileImageResult['profileImage']}');
      } else {
        print('Error loading profile image: Document not found.');
      }

    } catch (e) {
      print('Error uploading profile image: $e');
    }
  }





  Future<void> loadProfileImage(String email) async {
    try {
      // Using a SelectorBuilder explicitly
      var selector = where.eq('userEmail', email);
      var user = await MongoDatabase.userCollection.findOne(selector);

      if (user != null && user['profileImage'] != null) {
        // Successfully retrieved profile image
        String profileImage = user['profileImage'];
        print('Profile image loaded successfully: $profileImage');
      } else {
        print('Profile image not found');
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }


  /// Create a new user in MongoDB
  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      await MongoDatabase.insertUser(userData);
      print('User created successfully');
    } catch (e) {
      throw 'Error creating user: $e';
    }
  }

  /// Fetch a user's full name by email
  Future<String?> getFullNameByEmail(String email) async {
    try {
      final user = await MongoDatabase.findUser(email: email);
      if (user != null && user['userName'] is String) {
        return user['userName'] as String;
      }
      return null;
    } catch (e) {
      print('Error fetching full name for email $email: $e');
      throw Exception('Failed to fetch user name');
    }
  }
  Future<String?> getUserTypeFromMongoDB(String email) async {
    try {
      final user = await MongoDatabase.findUser(email: email);
      if (user != null && user['userType'] is String) {
        return user['userType'] as String;
      }
      return null;
    } catch (e) {
      print('Error fetching full name for email $email: $e');
      throw Exception('Failed to fetch user name');
    }
  }

  /// Fetch a user by their email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final user = await MongoDatabase.findUser(email: email);
      return user;
    } catch (e) {
      throw 'Error fetching user: $e';
    }
  }


  /// Update user details by their email
  Future<void> updateUser(String email, Map<String, dynamic> updatedData) async {
    try {
      final user = await MongoDatabase.findUser(email: email);
      if (user != null) {
        await MongoDatabase.updateUser({...user, ...updatedData});
        print('User updated successfully');
      } else {
        throw 'User not found';
      }
    } catch (e) {
      throw 'Error updating user: $e';
    }
  }

  /// Delete a user by their email
  Future<void> deleteUser(String email) async {
    try {
      final user = await MongoDatabase.findUser(email: email);
      if (user != null) {
        await MongoDatabase.userCollection.remove({'userEmail': email});
        print('User deleted successfully');
      } else {
        throw 'User not found';
      }
    } catch (e) {
      throw 'Error deleting user: $e';
    }
  }

  /// Get all users from MongoDB
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final users = await MongoDatabase.userCollection.find().toList();
      return users;
    } catch (e) {
      throw 'Error fetching users: $e';
    }
  }

  /// Check if a user exists by their email
  Future<bool> userExists(String email) async {
    try {
      final user = await MongoDatabase.findUser(email: email);
      return user != null;
    } catch (e) {
      throw 'Error checking if user exists: $e';
    }
  }
  /// Update specific user fields by their email
  Future<void> updateUserFields(String email, Map<String, dynamic> fieldsToUpdate) async {
    try {
      final query = {'userEmail': email};
      var updateData = modify;

      // Iterate over the map and add each field update to the ModifierBuilder
      fieldsToUpdate.forEach((key, value) {
        updateData = updateData.set(key, value);
      });

      final result = await MongoDatabase.userCollection.updateOne(
        query,
        updateData,
      );

      print('Update Result - Matched: ${result.nMatched}, Modified: ${result.nModified}');

      if (result.nMatched == 0) {
        print('No document matched the given email.');
      } else if (result.nModified == 0) {
        print('The document was matched, but no modification was made (fields might be the same).');
      } else {
        print('User fields updated successfully.');
      }
    } catch (e) {
      print('Error updating user fields: $e');
      throw 'Error updating user fields: $e';
    }
  }

  /// Close the MongoDB connection
  Future<void> closeConnection() async {
    try {
      await MongoDatabase.db.close();
      print('MongoDB connection closed');
    } catch (e) {
      throw 'Error closing MongoDB connection: $e';
    }
  }
}
