import 'dart:developer';
import 'package:mongo_dart/mongo_dart.dart';
import '../constants/text_strings.dart'; // Ensure this path is correct
import 'package:logger/logger.dart';

// Initialize a logger for better logging
final logger = Logger();

class MongoDatabase {
  static Db? _db;
  static DbCollection? _userPatientCollection;
  static DbCollection? _userLabCollection;
  static DbCollection? _userNurseCollection;
  static DbCollection? _userMedicalStoreCollection;
  static DbCollection? _medicalLabServices;
  static DbCollection? _userVerification;
  static DbCollection? _bookingsCollection;
  static DbCollection? _patientBookingsCollection;
  static DbCollection? _users;
  static DbCollection? _messagesCollection;

  // Connect to MongoDB and initialize the collections
  static Future<void> connect() async {
    try {
      // Connect to the MongoDB database
      _db = await Db.create(MONGO_URL);
      await _db!.open();

      // Access the collections from the database
      _userPatientCollection = _db!.collection(USER_PATIENT_COLLECTION_NAME);
      _userLabCollection = _db!.collection(USER_LAB_COLLECTION_NAME);
      _userNurseCollection = _db!.collection(USER_NURSE_COLLECTION_NAME);
      _userMedicalStoreCollection =
          _db!.collection(USER_MEDICAL_STORE_COLLECTION_NAME);
      _medicalLabServices = _db!.collection(LAB_SERVICES);
      _userVerification = _db!.collection(USER_VERIFICATION);
      _bookingsCollection = _db!.collection(LAB_BOOKINGS);
      _patientBookingsCollection = _db!.collection(PATIENT_LAB_BOOKINGS);
      _users = _db!.collection(USERS);
      _messagesCollection = _db!.collection(MESSAGES_COLLECTION_NAME);

      // Optional: Use inspect to debug the database connection
      inspect(_db);

      logger.i('Connected to MongoDB database successfully');
    } catch (e, stackTrace) {
      logger.e('Error connecting to MongoDB', error: e, stackTrace: stackTrace);
      rethrow; // Rethrow the exception if needed
    }
  }

  static DbCollection? get userPatientCollection => _userPatientCollection;
  static DbCollection? get userLabCollection => _userLabCollection;
  static DbCollection? get userNurseCollection => _userNurseCollection;
  static DbCollection? get userMedicalStoreCollection =>
      _userMedicalStoreCollection;
  static DbCollection? get medicalLabServices => _medicalLabServices;
  static DbCollection? get userVerification => _userVerification;
  static DbCollection? get bookingsCollection => _bookingsCollection;
  static DbCollection? get patientBookingsCollection =>
      _patientBookingsCollection;
  static DbCollection? get users => _users;
  static DbCollection? get messagesCollection => _messagesCollection;

  // Close the MongoDB connection
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _userPatientCollection = null;
      _userLabCollection = null;
      _userNurseCollection = null;
      _userMedicalStoreCollection = null;
      _medicalLabServices = null;
      _userVerification = null;
      _bookingsCollection = null;
      _patientBookingsCollection = null;
      _users = null;
      _messagesCollection = null;

      logger.i('MongoDB connection closed');
    }
  }

  //get all  messages globally

  static Future<List<Map<String, dynamic>>> getAllMessages() async {
    try {
      final messages = await _messagesCollection
          ?.find(where.sortBy('timestamp', descending: true))
          .toList();

      return messages?.map((doc) => doc).toList() ?? [];
    } catch (e, stackTrace) {
      logger.e('Error fetching all messages', error: e, stackTrace: stackTrace);
      return [];
    }
  }

// Insert a new message
  static Future<void> insertMessage(Map<String, dynamic> message) async {
    try {
      if (message.isEmpty ||
          !message.containsKey('fromId') ||
          !message.containsKey('toId')) {
        throw Exception('Invalid message data: Missing required fields');
      }

      // Add timestamp if missing
      if (!message.containsKey('sent')) {
        message['sent'] = DateTime.now().millisecondsSinceEpoch.toString();
      }

      await _messagesCollection?.insertOne(message);
      logger.i('Message inserted successfully');
    } catch (e, stackTrace) {
      logger.e('Error inserting message', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Fetch messages for a specific user
  static Future<List<Map<String, dynamic>>> findMessagesByUser(
      String userId) async {
    try {
      var messages = await _messagesCollection
          ?.find(where.raw({
            "\$or": [
              {"fromId": userId},
              {"toId": userId}
            ]
          }).sortBy('sent', descending: true))
          .toList();

      return messages?.map((doc) => doc).toList() ?? [];
    } catch (e, stackTrace) {
      logger.e('Error fetching messages', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Update a message (e.g., mark as read)
  static Future<void> updateMessage(
      String messageId, Map<String, dynamic> updatedFields) async {
    try {
      // Validate ObjectId by attempting to parse it
      ObjectId id;
      try {
        id = ObjectId.parse(messageId);
      } catch (e) {
        throw Exception('Invalid message ID format');
      }

      // Create a ModifierBuilder instance
      final modifier = ModifierBuilder();
      updatedFields.forEach((key, value) {
        modifier.set(key, value);
      });

      // Perform the update operation
      final result = await _messagesCollection?.updateOne(
        where.id(id), // Use the parsed ObjectId
        modifier,
      );

      if (result?.isSuccess == true) {
        logger.i('Message updated successfully');
      } else {
        logger.w('Message update failed or no changes made');
      }
    } catch (e, stackTrace) {
      logger.e('Error updating message', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Delete a message
  static Future<void> deleteMessage(String messageId) async {
    try {
      // Validate ObjectId by attempting to parse it
      ObjectId id;
      try {
        id = ObjectId.parse(messageId);
      } catch (e) {
        throw Exception('Invalid message ID format');
      }

      // Perform the delete operation
      final result = await _messagesCollection?.deleteOne(where.id(id));

      if (result?.isSuccess == true) {
        logger.i('Message deleted successfully');
      } else {
        logger.w('Message deletion failed or message not found');
      }
    } catch (e, stackTrace) {
      logger.e('Error deleting message', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Create indexes for messages collection
  static Future<void> createMessagesIndexes() async {
    try {
      await _messagesCollection?.createIndex(keys: {'sent': 1});
      await _messagesCollection?.createIndex(keys: {'fromId': 1, 'toId': 1});
      logger.i('Indexes created successfully for messages collection');
    } catch (e, stackTrace) {
      logger.e('Error creating messages indexes',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      if (_db == null) {
        throw Exception('Database connection is not established');
      }

      List<Map<String, dynamic>> allUsers = [];

      // List of all collections
      List<DbCollection?> collections = [
        _userPatientCollection,
        _userLabCollection,
        _userNurseCollection,
        _userMedicalStoreCollection,
        _medicalLabServices,
        _userVerification
      ];

      for (var collection in collections) {
        if (collection != null) {
          var users = await collection.find().toList();
          allUsers.addAll(users.map((doc) => doc)); // Ensure correct casting
        }
      }

      logger.i('Fetched all users successfully');
      return allUsers;
    } catch (e, stackTrace) {
      logger.e('Error fetching all users', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Function to insert a user document into the specified collection
  static Future<void> insertUser(
      Map<String, dynamic> user, DbCollection? collection) async {
    try {
      // Validate the input
      if (user.isEmpty || !user.containsKey('userEmail')) {
        throw Exception('Invalid user data: Missing required fields');
      }

      // Check for duplicate email
      final existingUser =
          await collection?.findOne({'userEmail': user['userEmail']});
      if (existingUser != null) {
        throw Exception('User with the same email already exists');
      }

      // Insert the user
      await collection?.insertOne(user);
      logger.i('User inserted successfully into ${collection?.collectionName}');
    } catch (e, stackTrace) {
      logger.e('Error inserting user', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Function to find a user by email in the specified collection
  static Future<Map<String, dynamic>?> findUser(
      {required String email, required DbCollection? collection}) async {
    try {
      if (email.isEmpty) {
        throw Exception('Email cannot be empty');
      }

      var user = await collection?.findOne({'userEmail': email});
      logger.i(user != null
          ? 'User found in ${collection?.collectionName}'
          : 'User not found in ${collection?.collectionName}');
      return user;
    } catch (e, stackTrace) {
      logger.e('Error finding user', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  static Future<bool> checkVerification({
    required String nic,
    required String licence,
    required DbCollection? collection,
  }) async {
    // Debug: Log the input parameters
    print("checkVerification called with NIC: $nic, Licence: $licence");

    // Check for empty input parameters and throw an exception if invalid
    if (nic.isEmpty || licence.isEmpty) {
      print("Error: NIC or License cannot be empty"); // Debugging message
      throw Exception('NIC or License cannot be empty');
    }

    try {
      // Debug: Log the start of the database query
      print("Querying database for userNic and userLicenseNumber");

      // Query to check if both NIC and License exist in the same document
      var userDoc = await collection?.findOne({
        'userNic': nic,
        'userLicenseNumber':
            licence, // Ensure both fields are in the same document
      });

      // Debug: Log the result of the query
      if (userDoc != null) {
        print("Verification successful: Document found: $userDoc");
        return true;
      } else {
        print("Verification failed: No matching document found.");
        return false;
      }
    } catch (e) {
      // Debug: Log any exception that occurs
      print("Error during checkVerification: $e");
      throw Exception("An error occurred during verification: $e");
    }
  }

  // Function to update user details (e.g., after login) in the specified collection
  static Future<void> updateUser(
      Map<String, dynamic> updatedUser, DbCollection? collection) async {
    try {
      var userId = updatedUser['userId'];
      if (userId == null) {
        throw Exception('User ID is required for updating');
      }

      // Create a ModifierBuilder
      final modifier = modify..set('lastLogin', DateTime.now());

      // Set each field in updatedUser
      updatedUser.forEach((key, value) {
        if (key != '_id') {
          // Avoid setting the _id field
          modifier.set(key, value);
        }
      });

      // Update the user document
      await collection?.updateOne(
        where.eq('_id', userId),
        modifier,
      );

      logger.i('User updated successfully in ${collection?.collectionName}');
    } catch (e, stackTrace) {
      logger.e('Error updating user', error: e, stackTrace: stackTrace);
      rethrow; // Rethrow the exception if needed
    }
  }

  // Function to create indexes on the specified collection
  static Future<void> createIndexes(DbCollection? collection) async {
    try {
      await collection?.createIndex(keys: {'userEmail': 1}, unique: true);
      logger.i('Indexes created successfully in ${collection?.collectionName}');
    } catch (e, stackTrace) {
      logger.e('Error creating indexes', error: e, stackTrace: stackTrace);
      rethrow; // Rethrow the exception if needed
    }
  }

  // Specific methods for each collection

  //user verification
  static Future<void> insertVerifiedUsers(Map<String, dynamic> user) async {
    await insertUser(user, _medicalLabServices);
  }

  static Future<Map<String, dynamic>?> findVerifiedUsers(String email) async {
    return await findUser(email: email, collection: _medicalLabServices);
  }

  static Future<void> updateVerifiedUsers(
      Map<String, dynamic> updatedUser) async {
    await updateUser(updatedUser, _medicalLabServices);
  }

  static Future<void> createVerifiedUsersIndexes() async {
    await createIndexes(_medicalLabServices);
  }

  //Lab booking
  static Future<void> insertLabBooking(Map<String, dynamic> user) async {
    await insertUser(user, _bookingsCollection);
  }

  static Future<Map<String, dynamic>?> findBooking(String email) async {
    return await findUser(email: email, collection: _bookingsCollection);
  }

  static Future<void> updateBooking(Map<String, dynamic> updatedUser) async {
    await updateUser(updatedUser, _bookingsCollection);
  }

  static Future<void> createBookingIndexes() async {
    await createIndexes(_bookingsCollection);
  }

//Patient booking
  static Future<void> insertPatientLabBooking(Map<String, dynamic> user) async {
    await insertUser(user, _patientBookingsCollection);
  }

  static Future<Map<String, dynamic>?> findPatientBooking(String email) async {
    return await findUser(email: email, collection: _patientBookingsCollection);
  }

  static Future<void> updatePatientBooking(
      Map<String, dynamic> updatedUser) async {
    await updateUser(updatedUser, _patientBookingsCollection);
  }

  static Future<void> createPatientBookingIndexes() async {
    await createIndexes(_patientBookingsCollection);
  }

  //Lab services
  static Future<void> insertLabServices(Map<String, dynamic> user) async {
    await insertUser(user, _medicalLabServices);
  }

  static Future<Map<String, dynamic>?> findLabServices(String email) async {
    return await findUser(email: email, collection: _medicalLabServices);
  }

  static Future<void> updateLabServices(
      Map<String, dynamic> updatedUser) async {
    await updateUser(updatedUser, _medicalLabServices);
  }

  static Future<void> createLabServicesIndexes() async {
    await createIndexes(_medicalLabServices);
  }

  // Insert user into the userPatient collection
  static Future<void> insertUserPatient(Map<String, dynamic> user) async {
    await insertUser(user, _userPatientCollection);
  }

  // Find user in the userPatient collection
  static Future<Map<String, dynamic>?> findUserPatient(String email) async {
    return await findUser(email: email, collection: _userPatientCollection);
  }

  // Update user in the userPatient collection
  static Future<void> updateUserPatient(
      Map<String, dynamic> updatedUser) async {
    await updateUser(updatedUser, _userPatientCollection);
  }

  // Create indexes in the userPatient collection
  static Future<void> createUserPatientIndexes() async {
    await createIndexes(_userPatientCollection);
  }

  // Repeat for userLab, userNurse, and userMedicalStore collections

  static Future<void> insertUserLab(Map<String, dynamic> user) async {
    await insertUser(user, _userLabCollection);
  }

  static Future<Map<String, dynamic>?> findUserLab(String email) async {
    return await findUser(email: email, collection: _userLabCollection);
  }

  static Future<void> updateUserLab(Map<String, dynamic> updatedUser) async {
    await updateUser(updatedUser, _userLabCollection);
  }

  static Future<void> createUserLabIndexes() async {
    await createIndexes(_userLabCollection);
  }

  static Future<void> insertUserNurse(Map<String, dynamic> user) async {
    await insertUser(user, _userNurseCollection);
  }

  static Future<Map<String, dynamic>?> findUserNurse(String email) async {
    return await findUser(email: email, collection: _userNurseCollection);
  }

  static Future<void> updateUserNurse(Map<String, dynamic> updatedUser) async {
    await updateUser(updatedUser, _userNurseCollection);
  }

  static Future<void> createUserNurseIndexes() async {
    await createIndexes(_userNurseCollection);
  }

  static Future<void> insertUserMedicalStore(Map<String, dynamic> user) async {
    await insertUser(user, _userMedicalStoreCollection);
  }

  static Future<Map<String, dynamic>?> findUserMedicalStore(
      String email) async {
    return await findUser(
        email: email, collection: _userMedicalStoreCollection);
  }

  static Future<void> updateUserMedicalStore(
      Map<String, dynamic> updatedUser) async {
    await updateUser(updatedUser, _userMedicalStoreCollection);
  }

  static Future<void> createUserMedicalStoreIndexes() async {
    await createIndexes(_userMedicalStoreCollection);
  }
}
