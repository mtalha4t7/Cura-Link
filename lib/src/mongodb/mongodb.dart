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
      logger.i('MongoDB connection closed');
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
