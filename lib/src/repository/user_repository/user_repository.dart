import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:cura_link/src/mongodb/mongodb.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:image_picker/image_picker.dart';
import '../../screens/features/authentication/models/message_model.dart';


class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  final ImagePicker _picker = ImagePicker();
  final StreamController<List<Map<String, dynamic>>> _usersController =
  StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _messagesController =
  StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<void> _newMessagesController =
  StreamController<void>.broadcast();

  String currentUserEmail = FirebaseAuth.instance.currentUser!.email.toString();

  /// Stream that emits when new messages arrive
  Stream<void> getNewMessagesStream() => _newMessagesController.stream;

  /// Upload profile image for a specific user type
  Future<void> uploadProfileImage({
    required String email,
    required String base64Image,
    required DbCollection? collection,
  }) async {
    try {
      log('Attempting to update profile image for: $email');

      // Query to find the current profile
      final query = {'userEmail': email};
      final currentProfile = await collection?.findOne(query);
      final col = MongoDatabase.users;
      final usersProfile = await col?.findOne(query);

      if (currentProfile == null) {
        log('No document found for email: $email');
        return;
      }

      if (currentProfile['profileImage'] == base64Image) {
        log('New image is the same as the current one. No update needed.');
        return;
      }

      // Update the profile image
      final result = await collection?.updateOne(
        query,
        modify.set('profileImage', base64Image),
      );
      final result1 = await col?.updateOne(
        query,
        modify.set('profileImage', base64Image),
      );

      log('Update Result - Matched: ${result?.nMatched}, Modified: ${result?.nModified}');
    } catch (e) {
      log('Error uploading profile image: $e');
      rethrow;
    }
  }

  /// Load profile image for a specific user type
  Future<void> loadProfileImage({
    required String email,
    required DbCollection? collection,
  }) async {
    try {
      final query = where.eq('userEmail', email);
      final user = await collection?.findOne(query);

      if (user != null && user['profileImage'] != null) {
        log('Profile image loaded successfully: ${user['profileImage']}');
      } else {
        log('Profile image not found');
      }
    } catch (e) {
      log('Error loading profile image: $e');
      rethrow;
    }
  }

  /// Get current authenticated user email
  Future<String?> getCurrentUser() async {
    return FirebaseAuth.instance.currentUser?.email;
  }

  /// Get user by name from all collections
  Future<Map<String, dynamic>?> getUserByName(String name) async {
    List<DbCollection?> collections = [
      _patientCollection,
      _labCollection,
      _nurseCollection,
      _medicalStoreCollection
    ];

    for (var collection in collections) {
      if (collection != null) {
        final user = await collection.findOne(where.eq('userName', name));
        if (user != null) {
          return user;
        }
      }
    }
    return null;
  }

  Future<String?> getCurrentUserMongoEmail() async {
    final email = FirebaseAuth.instance.currentUser?.email;

    if (email == null) return null;

    List<DbCollection?> collections = [
      _patientCollection,
      _labCollection,
      _nurseCollection,
      _medicalStoreCollection
    ];

    for (var collection in collections) {
      if (collection != null) {
        final user = await collection.findOne(where.eq('userEmail', email));
        if (user != null && user['userEmail'] != null) {
          debugPrint("User found in collection: ${collection.collectionName}");
          debugPrint("MongoDB _id: ${user['_id']}");
          return user['userEmail'];
        }
      }
    }

    debugPrint("No user found with email: $email in any collection.");
    return null;
  }

  /// Get all users from all collections
  Future<List<Map<String, dynamic>>> getAllUsersFromAllCollections() async {
    return await MongoDatabase.getAllUsers();
  }

  /// Fetch a user by email from all collections
  Future<Map<String, dynamic>?> getUserByEmailFromAllCollections(String email) async {
    List<DbCollection?> collections = [
      _patientCollection,
      _labCollection,
      _nurseCollection,
      _medicalStoreCollection
    ];

    for (var collection in collections) {
      if (collection != null) {
        final user = await collection.findOne(where.eq('userEmail', email));
        if (user != null) {
          return user;
        }
      }
    }
    return null;
  }

  /// Create a new user in a specific collection
  Future<void> createUser({
    required Map<String, dynamic> userData,
    required DbCollection? collection,
  }) async {
    try {
      await MongoDatabase.insertUser(userData, collection);
      log('User created successfully in ${collection?.collectionName}');
    } catch (e) {
      log('Error creating user: $e');
      rethrow;
    }
  }

  /// Send message to database
  Future<void> sendMessageToDatabase(Message message) async {
    try {
      var collection = MongoDatabase.messagesCollection;
      if (collection != null) {
        await collection.insertOne(message.toJson());
        _fetchMessages(message.toId);
        _newMessagesController.add(null); // Notify about new message
      } else {
        throw Exception("Messages collection is not initialized");
      }
    } catch (e) {
      log('Error sending message: $e');
      rethrow;
    }
  }

  /// Update user's last active timestamp
  Future<void> updateUserLastActive(String userEmail) async {
    try {
      final collection = MongoDatabase.users;
      if (collection != null) {
        await collection.updateOne(
          {'userEmail': userEmail},
          {'\$set': {'userLastActive': DateTime.now().millisecondsSinceEpoch}},
        );
      }
    } catch (e) {
      log("Error updating user last active: $e");
      rethrow;
    }
  }

  /// Update user's active status
  Future<void> updateActiveStatus(bool isActive) async {
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) return;

      List<DbCollection?> collections = [
        _patientCollection,
        _labCollection,
        _nurseCollection,
        _medicalStoreCollection
      ];

      for (DbCollection? collection in collections) {
        if (collection == null) continue;

        final user = await collection.findOne({'email': userEmail});
        if (user != null) {
          await collection.updateOne(
            {'email': userEmail},
            {'\$set': {'isActive': isActive}},
          );
          log('User active status updated in ${collection.collectionName} to: $isActive');
          return;
        }
      }

      log('User not found in any collection');
    } catch (e) {
      log('Error updating active status: $e');
      rethrow;
    }
  }

  /// Fetch user details by email for a specific collection
  Future<Map<String, dynamic>?> getUserByEmail({
    required String email,
    required DbCollection? collection,
  }) async {
    try {
      return await MongoDatabase.findUser(email: email, collection: collection);
    } catch (e) {
      log('Error fetching user: $e');
      rethrow;
    }
  }

  /// Update user details in a specific collection
  Future<void> updateUser({
    required String email,
    required Map<String, dynamic> updatedData,
    required DbCollection? collection,
  }) async {
    try {
      final user = await MongoDatabase.findUser(email: email, collection: collection);
      if (user != null) {
        await MongoDatabase.updateUser({...user, ...updatedData}, collection);
        log('User updated successfully in ${collection?.collectionName}');
      } else {
        throw 'User not found';
      }
    } catch (e) {
      log('Error updating user: $e');
      rethrow;
    }
  }

  /// Delete a user by email from a specific collection
  Future<void> deleteUser({
    required String email,
    required DbCollection? collection,
  }) async {
    try {
      final result = await collection?.deleteOne({'userEmail': email});
      if (result?.nRemoved == 1) {
        log('User deleted successfully from ${collection?.collectionName}');
      } else {
        throw 'User not found';
      }
    } catch (e) {
      log('Error deleting user: $e');
      rethrow;
    }
  }

  /// Get all users from a specific collection
  Future<List<Map<String, dynamic>>> getAllUsers(DbCollection? collection) async {
    try {
      return await collection?.find().toList() ?? [];
    } catch (e) {
      log('Error fetching users: $e');
      rethrow;
    }
  }

  /// Get stream of all users with their chat information
  Stream<List<Map<String, dynamic>>> getChatUsersWithMessages() {
    _fetchChatUsers();
    return _usersController.stream;
  }

  /// Fetch chat users with their last messages and unread counts



  Future<void> fetchChatUsers() async {
    await _fetchChatUsers();
  }

  Future<void> _fetchChatUsers() async {
    try {
      final currentUserEmail = await getCurrentUser();
      if (currentUserEmail == null) return;

      final messageCollection = MongoDatabase.messagesCollection;
      final collections = [
        MongoDatabase.userPatientCollection,
        MongoDatabase.userLabCollection,
        MongoDatabase.userNurseCollection,
        MongoDatabase.userMedicalStoreCollection,
      ];

      // Fetch all messages involving the current user
      final messages = await messageCollection?.find({
        '\$or': [
          {'fromId': currentUserEmail},
          {'toId': currentUserEmail},
        ]
      }).toList() ?? [];

      // Extract unique other user emails
      final otherUserEmails = <String>{};
      for (var msg in messages) {
        final fromId = msg['fromId'];
        final toId = msg['toId'];
        if (fromId != currentUserEmail) otherUserEmails.add(fromId);
        if (toId != currentUserEmail) otherUserEmails.add(toId);
      }

      List<Map<String, dynamic>> enrichedUsers = [];

      for (final userEmail in otherUserEmails) {
        // Search for user in all collections
        Map<String, dynamic>? userData;
        for (var collection in collections) {
          if (collection == null) continue;
          userData = await collection.findOne({'userEmail': userEmail});
          if (userData != null) break; // Found user, stop searching
        }

        if (userData == null) continue; // Skip if user not found

        // Fetch messages between current user and this user
        final chatMessages = await messageCollection?.find({
          '\$or': [
            {'fromId': currentUserEmail, 'toId': userEmail},
            {'fromId': userEmail, 'toId': currentUserEmail},
          ]
        }).toList() ?? [];

        if (chatMessages.isEmpty) continue;

        // Sort by 'sent' timestamp to find latest
        chatMessages.sort((a, b) {
          final aTime = int.tryParse(a['sent']?.toString() ?? '') ?? 0;
          final bTime = int.tryParse(b['sent']?.toString() ?? '') ?? 0;
          return bTime.compareTo(aTime);
        });

        final latestMessage = chatMessages.first;

        // Count unread messages sent by this user to current user
        final unreadCount = chatMessages.where((msg) =>
        msg['fromId'] == userEmail &&
            msg['toId'] == currentUserEmail &&
            (msg['read'] == 'false' || msg['read'] == false)).length;

        enrichedUsers.add({
          ...userData,
          'lastMessage': latestMessage['msg'],
          'lastMessageTime': latestMessage['sent'],
          'unreadCount': unreadCount,
        });
      }

      // Sort enriched users by last message time (newest first)
      enrichedUsers.sort((a, b) {
        final aTime = int.tryParse(a['lastMessageTime']?.toString() ?? '') ?? 0;
        final bTime = int.tryParse(b['lastMessageTime']?.toString() ?? '') ?? 0;
        return bTime.compareTo(aTime);
      });

      // Add to stream
      if (!_usersController.isClosed) {
        _usersController.add(enrichedUsers);
      }
    } catch (e, stack) {
      log('Error fetching chat users: $e');
      log('$stack');
      if (!_usersController.isClosed) {
        _usersController.addError('Error fetching chat users: $e');
      }
    }
  }

  /// Mark messages as read between current user and another user
  Future<void> markMessagesAsRead(String currentUserEmail, String otherUserEmail) async {
    try {
      await MongoDatabase.messagesCollection?.updateMany(
        {
          'fromId': otherUserEmail,
          'toId': currentUserEmail,
          'read': 'false',
        },
        {'\$set': {'read': 'true'}},
      );
      _fetchChatUsers(); // Refresh the user list
    } catch (e) {
      log('Error marking messages as read: $e');
      rethrow;
    }
  }

  /// Get stream of all messages between current user and another user
  Stream<List<Map<String, dynamic>>> getAllMessagesStream(String to) {
    _fetchMessages(to);
    return _messagesController.stream;
  }

  /// Fetch messages between current user and another user

  Future<void> _fetchMessages(String to) async {
    try {
      var collection = MongoDatabase.messagesCollection;
      final messages = await collection?.find({
        '\$or': [
          {'fromId': currentUserEmail, 'toId': to},
          {'fromId': to, 'toId': currentUserEmail},
        ]
      }).toList() ?? [];

      if (_messagesController.isClosed) return;
      _messagesController.add(messages);
    } catch (e) {
      log('Error fetching messages: $e');
      if (!_messagesController.isClosed) {
        _messagesController.addError('Error fetching messages: $e');
      }
    }
  }

  /// Check if a user exists in a specific collection
  Future<bool> userExists({
    required String email,
    required DbCollection? collection,
  }) async {
    try {
      final user = await MongoDatabase.findUser(email: email, collection: collection);
      return user != null;
    } catch (e) {
      log('Error checking if user exists: $e');
      rethrow;
    }
  }

  /// Get user's full name by email from a specific collection
  Future<String?> getFullNameByEmail({
    required String email,
    required DbCollection? collection,
  }) async {
    try {
      final user = await MongoDatabase.findUser(email: email, collection: collection);
      if (user != null && user['userName'] is String) {
        return user['userName'] as String;
      }
      return null;
    } catch (e) {
      log('Error fetching full name for email $email: $e');
      throw Exception('Failed to fetch user name');
    }
  }

  /// Get user's phone number by email from a specific collection
  Future<String?> getPhoneNumberByEmail({
    required String email,
    required DbCollection? collection,
  }) async {
    try {
      final user = await MongoDatabase.findUser(email: email, collection: collection);
      if (user != null && user['userPhone'] is String) {
        return user['userPhone'] as String;
      }
      return null;
    } catch (e) {
      log('Error fetching phone number for email $email: $e');
      throw Exception('Failed to fetch user phone number');
    }
  }

  /// Get user type by email from a specific collection
  Future<String?> getUserTypeFromMongoDB({
    required String email,
    required DbCollection? collection,
  }) async {
    try {
      final user = await MongoDatabase.findUser(email: email, collection: collection);
      if (user != null && user['userType'] is String) {
        return user['userType'] as String;
      }
      return null;
    } catch (e) {
      log('Error fetching user type for email $email: $e');
      throw Exception('Failed to fetch user type');
    }
  }

  /// Get verification status by email from a specific collection
  Future<int?> getVerification({
    required String email,
    required DbCollection? collection,
  }) async {
    try {
      final user = await MongoDatabase.findUser(email: email, collection: collection);
      if (user != null && user['userVerified'] is int) {
        return user['userVerified'] as int;
      }
      return null;
    } catch (e) {
      log('Error fetching verification status for email $email: $e');
      throw Exception('Failed to fetch verification status');
    }
  }

  /// Send an image message
  Future<void> sendImageMessage({
    required String toId,
    required String fromId,
    required XFile imageFile,
  }) async {
    try {
      final collection = MongoDatabase.messagesCollection;
      if (collection == null) {
        throw Exception("Messages collection is not initialized");
      }

      // Read and compress the image
      final imageBytes = await imageFile.readAsBytes();
      final compressedBytes = await _compressImage(imageBytes);
      final imageBase64 = base64Encode(compressedBytes);

      // Create message
      final message = Message(
        toId: toId,
        fromId: fromId,
        msg: imageBase64,
        read: "false",
        type: MessageType.image,
        sent: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      await collection.insertOne(message.toJson());
      await updateUserLastActive(fromId);
      _fetchMessages(toId);
      _newMessagesController.add(null); // Notify about new message

    } catch (e) {
      debugPrint('Image send error: $e');
      throw Exception('Image send failed: ${e.toString()}');
    }
  }

  /// Compress image to reduce size
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      // Skip compression if image is already small (under 1MB)
      if (bytes.lengthInBytes < 1024 * 1024) {
        return bytes;
      }

      // Get the original image dimensions
      final originalImage = await decodeImageFromList(bytes);
      final originalWidth = originalImage.width.toDouble();
      final originalHeight = originalImage.height.toDouble();

      // Calculate target dimensions while maintaining aspect ratio
      const maxDimension = 1920.0; // Max width or height
      double width = originalWidth;
      double height = originalHeight;

      if (width > height && width > maxDimension) {
        height = (height * maxDimension / width);
        width = maxDimension;
      } else if (height > maxDimension) {
        width = (width * maxDimension / height);
        height = maxDimension;
      }

      // Perform the compression
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: width.toInt(),
        minHeight: height.toInt(),
        quality: 85,
        format: CompressFormat.jpeg,
        rotate: 0,
      );

      // If compression fails, return original but log warning
      if (result == null || result.isEmpty) {
        debugPrint('Image compression failed - using original image');
        return bytes;
      }

      // Verify the compressed size is reasonable
      if (result.lengthInBytes > bytes.lengthInBytes) {
        debugPrint('Compressed image larger than original - using original');
        return bytes;
      }

      return result;
    } catch (e) {
      debugPrint('Image compression error: $e');
      return bytes; // Fallback to original if compression fails
    }
  }

  // Collection getters for different user types

  DbCollection? get _patientCollection => MongoDatabase.userPatientCollection;
  DbCollection? get _labCollection => MongoDatabase.userLabCollection;
  DbCollection? get _nurseCollection => MongoDatabase.userNurseCollection;
  DbCollection? get _medicalStoreCollection => MongoDatabase.userMedicalStoreCollection;
  DbCollection? get _verificationCollection => MongoDatabase.userVerification;

  // Patient-specific methods
  Future<void> createPatient(Map<String, dynamic> data) => createUser(userData: data, collection: _patientCollection);
  Future<Map<String, dynamic>?> getPatientByEmail(String email) => getUserByEmail(email: email, collection: _patientCollection);
  Future<void> updatePatient(String email, Map<String, dynamic> updatedData) => updateUser(email: email, updatedData: updatedData, collection: _patientCollection);
  Future<void> deletePatient(String email) => deleteUser(email: email, collection: _patientCollection);
  Future<List<Map<String, dynamic>>> getAllPatients() => getAllUsers(_patientCollection);
  Future<bool> patientExists(String email) => userExists(email: email, collection: _patientCollection);
  Future<String?> getPatientUserType(String email) => getUserTypeFromMongoDB(email: email, collection: _patientCollection);
  Future<String?> getPatientUserName(String email) => getFullNameByEmail(email: email, collection: _patientCollection);
  Future<String?> getPatientUserPhone(String email) => getPhoneNumberByEmail(email: email, collection: _patientCollection);

  // Lab-specific methods
  Future<void> createLabUser(Map<String, dynamic> data) => createUser(userData: data, collection: _labCollection);
  Future<Map<String, dynamic>?> getLabUserByEmail(String email) => getUserByEmail(email: email, collection: _labCollection);
  Future<void> updateLabUser(String email, Map<String, dynamic> updatedData) => updateUser(email: email, updatedData: updatedData, collection: _labCollection);
  Future<void> deleteLabUser(String email) => deleteUser(email: email, collection: _labCollection);
  Future<List<Map<String, dynamic>>> getAllLabUsers() => getAllUsers(_labCollection);
  Future<bool> labUserExists(String email) => userExists(email: email, collection: _labCollection);
  Future<String?> getLabUserType(String email) => getUserTypeFromMongoDB(email: email, collection: _labCollection);
  Future<int?> getLabVerification(String email) => getVerification(email: email, collection: _labCollection);
  Future<String?> getLabUserName(String email) => getFullNameByEmail(email: email, collection: _labCollection);
  Future<String?> getLabUserPhone(String email) => getPhoneNumberByEmail(email: email, collection: _labCollection);

  // Nurse-specific methods
  Future<void> createNurseUser(Map<String, dynamic> data) => createUser(userData: data, collection: _nurseCollection);
  Future<Map<String, dynamic>?> getNurseUserByEmail(String email) => getUserByEmail(email: email, collection: _nurseCollection);

  Future<bool> updateNurseUser(String email, Map<String, dynamic> updates) async {
    try {
      final collection = MongoDatabase.userNurseCollection;

      // Create the update document manually
      final updateDoc = {
        '\$set': {...updates}  // Spread operator to include all updates
      };

      // Remove null values from updates
      updateDoc['\$set']?.removeWhere((key, value) => value == null);

      if (updateDoc['\$set']?.isEmpty ?? true) {
        throw ArgumentError('No valid fields to update');
      }

      final result = await collection?.updateOne(
        where.eq('userEmail', email),
        updateDoc,
      );

      if (result == null || !result.isSuccess) {
        throw Exception('Update operation failed: ${result?.errmsg}');
      }

      return true;
    } catch (e) {
      print('Error updating nurse user: $e');
      rethrow;
    }
  }


  Future<void> deleteNurseUser(String email) => deleteUser(email: email, collection: _nurseCollection);
  Future<List<Map<String, dynamic>>> getAllNurseUsers() => getAllUsers(_nurseCollection);
  Future<bool> nurseUserExists(String email) => userExists(email: email, collection: _nurseCollection);
  Future<String?> getNurseUserType(String email) => getUserTypeFromMongoDB(email: email, collection: _nurseCollection);
  Future<String?> getNurseUserName(String email) => getFullNameByEmail(email: email, collection: _nurseCollection);
  Future<String?> getNursePhone(String email) => getPhoneNumberByEmail(email: email, collection: _nurseCollection);

  // Medical Store-specific methods
  Future<void> createMedicalStoreUser(Map<String, dynamic> data) => createUser(userData: data, collection: _medicalStoreCollection);
  Future<Map<String, dynamic>?> getMedicalStoreUserByEmail(String email) => getUserByEmail(email: email, collection: _medicalStoreCollection);
  Future<void> updateMedicalStoreUser(String email, Map<String, dynamic> updatedData) => updateUser(email: email, updatedData: updatedData, collection: _medicalStoreCollection);
  Future<void> deleteMedicalStoreUser(String email) => deleteUser(email: email, collection: _medicalStoreCollection);
  Future<List<Map<String, dynamic>>> getAllMedicalStoreUsers() => getAllUsers(_medicalStoreCollection);
  Future<bool> medicalStoreUserExists(String email) => userExists(email: email, collection: _medicalStoreCollection);
  Future<String?> getMedicalStoreUserType(String email) => getUserTypeFromMongoDB(email: email, collection: _medicalStoreCollection);
  Future<String?> getMedicalStoreUserName(String email) => getFullNameByEmail(email: email, collection: _medicalStoreCollection);
  Future<String?> getMedicalStorePhone(String email) => getPhoneNumberByEmail(email: email, collection: _nurseCollection);

  @override
  void onClose() {
    _usersController.close();
    _messagesController.close();
    _newMessagesController.close();
    super.onClose();
  }


}
