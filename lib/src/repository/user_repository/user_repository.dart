import 'dart:async';
import 'dart:developer';
import 'package:cura_link/src/mongodb/mongodb.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:image_picker/image_picker.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();
  final ImagePicker _picker = ImagePicker();

  /// Upload profile image for a specific user type
  Future<void> uploadProfileImage(
      {required String email,
      required String base64Image,
      required DbCollection? collection}) async {
    try {
      print('Attempting to update profile image for: $email');

      // Query to find the current profile
      final query = {'userEmail': email};
      final currentProfile = await collection?.findOne(query);
      final col = MongoDatabase.users;
      final usersProfile = await col?.findOne(query);

      if (currentProfile == null) {
        print('No document found for email: $email');
        return;
      }

      if (currentProfile['profileImage'] == base64Image) {
        print('New image is the same as the current one. No update needed.');
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

      print(
          'Update Result - Matched: ${result?.nMatched}, Modified: ${result?.nModified}');
    } catch (e) {
      print('Error uploading profile image: $e');
    }
  }

  /// Load profile image for a specific user type
  Future<void> loadProfileImage(
      {required String email, required DbCollection? collection}) async {
    try {
      final query = where.eq('userEmail', email);
      final user = await collection?.findOne(query);

      if (user != null && user['profileImage'] != null) {
        print('Profile image loaded successfully: ${user['profileImage']}');
      } else {
        print('Profile image not found');
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

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

  Future<List<Map<String, dynamic>>> getAllUsersFromAllCollections() async {
    List<Map<String, dynamic>> allUsers = await MongoDatabase.getAllUsers();
    return allUsers;
  }

  /// Fetch a user by email from all collections
  Future<Map<String, dynamic>?> getUserByEmailFromAllCollections(
      String email) async {
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
  Future<void> createUser(
      {required Map<String, dynamic> userData,
      required DbCollection? collection}) async {
    try {
      await MongoDatabase.insertUser(userData, collection);
      print('User created successfully in ${collection?.collectionName}');
    } catch (e) {
      print('Error creating user: $e');
      throw 'Error creating user: $e';
    }
  }

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

        // Check if user exists in this collection
        final user = await collection.findOne({'email': userEmail});
        if (user != null) {
          await collection.updateOne(
            {'email': userEmail},
            {
              '\$set': {'isActive': isActive}
            },
          );
          log('User active status updated in ${collection.collectionName} to: $isActive');
          return; // Exit after updating the first matching collection
        }
      }

      log('User not found in any collection');
    } catch (e) {
      log('Error updating active status: $e');
    }
  }

  /// Fetch a user's details by email for a specific collection
  Future<Map<String, dynamic>?> getUserByEmail(
      {required String email, required DbCollection? collection}) async {
    try {
      final user =
          await MongoDatabase.findUser(email: email, collection: collection);
      return user;
    } catch (e) {
      print('Error fetching user: $e');
      throw 'Error fetching user: $e';
    }
  }

  /// Update user details in a specific collection
  Future<void> updateUser(
      {required String email,
      required Map<String, dynamic> updatedData,
      required DbCollection? collection}) async {
    try {
      final user =
          await MongoDatabase.findUser(email: email, collection: collection);
      if (user != null) {
        await MongoDatabase.updateUser({...user, ...updatedData}, collection);
        print('User updated successfully in ${collection?.collectionName}');
      } else {
        throw 'User not found';
      }
    } catch (e) {
      print('Error updating user: $e');
      throw 'Error updating user: $e';
    }
  }

  /// Delete a user by email from a specific collection
  Future<void> deleteUser(
      {required String email, required DbCollection? collection}) async {
    try {
      final result = await collection?.deleteOne({'userEmail': email});
      if (result?.nRemoved == 1) {
        print('User deleted successfully from ${collection?.collectionName}');
      } else {
        throw 'User not found';
      }
    } catch (e) {
      print('Error deleting user: $e');
      throw 'Error deleting user: $e';
    }
  }

  /// Get all users from a specific collection
  Future<List<Map<String, dynamic>>> getAllUsers(
      DbCollection? collection) async {
    try {
      final users = await collection?.find().toList() ?? [];
      return users;
    } catch (e) {
      print('Error fetching users: $e');
      throw 'Error fetching users: $e';
    }
  }

  final StreamController<List<Map<String, dynamic>>> _usersController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  String currentUserEmail = FirebaseAuth.instance.currentUser!.email
      .toString(); // Replace with the actual logged-in user's email

  Stream<List<Map<String, dynamic>>> getAllUsers1() {
    _fetchUsers(); // Fetch users initially
    return _usersController.stream;
  }

  Future<void> _fetchUsers() async {
    try {
      var collection = MongoDatabase.users;
      final users = await collection?.find().toList() ?? [];

      // Filter out the current user
      final filteredUsers =
          users.where((user) => user['userEmail'] != currentUserEmail).toList();

      _usersController.add(filteredUsers); // Emit filtered data
    } catch (e) {
      print('Error fetching users: $e');
      _usersController.addError('Error fetching users: $e');
    }
  }

  /// Check if a user exists in a specific collection
  Future<bool> userExists(
      {required String email, required DbCollection? collection}) async {
    try {
      final user =
          await MongoDatabase.findUser(email: email, collection: collection);
      return user != null;
    } catch (e) {
      print('Error checking if user exists: $e');
      throw 'Error checking if user exists: $e';
    }
  }

  Future<String?> getFullNameByEmail(
      {required String email, required DbCollection? collection}) async {
    try {
      final user =
          await MongoDatabase.findUser(email: email, collection: collection);
      if (user != null && user['userName'] is String) {
        return user['userName'] as String;
      }
      return null;
    } catch (e) {
      print('Error fetching full name for email $email: $e');
      throw Exception('Failed to fetch user name');
    }
  }

  Future<String?> getPhoneNumberByEmail(
      {required String email, required DbCollection? collection}) async {
    try {
      final user =
          await MongoDatabase.findUser(email: email, collection: collection);
      if (user != null && user['userPhone'] is String) {
        return user['userPhone'] as String;
      }
      return null;
    } catch (e) {
      print('Error fetching full name for email $email: $e');
      throw Exception('Failed to fetch user name');
    }
  }

  Future<String?> getUserTypeFromMongoDB(
      {required String email, required DbCollection? collection}) async {
    try {
      final user =
          await MongoDatabase.findUser(email: email, collection: collection);
      if (user != null && user['userType'] is String) {
        return user['userType'] as String;
      }
      return null;
    } catch (e) {
      print('Error fetching full name for email $email: $e');
      throw Exception('Failed to fetch user name');
    }
  }

  Future<int?> getVerification(
      {required String email, required DbCollection? collection}) async {
    try {
      final user =
          await MongoDatabase.findUser(email: email, collection: collection);
      if (user != null && user['userVerified'] is int) {
        return user['userVerified'] as int;
      }
      return null;
    } catch (e) {
      print('Error fetching full name for email $email: $e');
      throw Exception('Failed to fetch user name');
    }
  }

  /// Fetch a user by their email

  DbCollection? get _patientCollection => MongoDatabase.userPatientCollection;

  Future<void> createPatient(Map<String, dynamic> data) =>
      createUser(userData: data, collection: _patientCollection);

  Future<Map<String, dynamic>?> getPatientByEmail(String email) =>
      getUserByEmail(email: email, collection: _patientCollection);

  Future<void> updatePatient(String email, Map<String, dynamic> updatedData) =>
      updateUser(
          email: email,
          updatedData: updatedData,
          collection: _patientCollection);

  Future<void> deletePatient(String email) =>
      deleteUser(email: email, collection: _patientCollection);

  Future<List<Map<String, dynamic>>> getAllPatients() =>
      getAllUsers(_patientCollection);

  Future<bool> patientExists(String email) =>
      userExists(email: email, collection: _patientCollection);

  Future<String?> getPatientUserType(String email) =>
      getUserTypeFromMongoDB(email: email, collection: _patientCollection);

  Future<String?> getPatientUserName(String email) =>
      getFullNameByEmail(email: email, collection: _patientCollection);

  Future<String?> getPatientUserPhone(String email) =>
      getPhoneNumberByEmail(email: email, collection: _patientCollection);

  // Lab
  DbCollection? get _labCollection => MongoDatabase.userLabCollection;

  Future<void> createLabUser(Map<String, dynamic> data) =>
      createUser(userData: data, collection: _labCollection);

  Future<Map<String, dynamic>?> getLabUserByEmail(String email) =>
      getUserByEmail(email: email, collection: _labCollection);

  Future<void> updateLabUser(String email, Map<String, dynamic> updatedData) =>
      updateUser(
          email: email, updatedData: updatedData, collection: _labCollection);

  Future<void> deleteLabUser(String email) =>
      deleteUser(email: email, collection: _labCollection);

  Future<List<Map<String, dynamic>>> getAllLabUsers() =>
      getAllUsers(_labCollection);

  Future<bool> labUserExists(String email) =>
      userExists(email: email, collection: _labCollection);

  Future<String?> getLabUserType(String email) =>
      getUserTypeFromMongoDB(email: email, collection: _labCollection);

  Future<int?> getLabVerification(String email) =>
      getVerification(email: email, collection: _labCollection);

  Future<String?> getLabUserName(String email) =>
      getFullNameByEmail(email: email, collection: _labCollection);

  Future<String?> getLabUserPhone(String email) =>
      getPhoneNumberByEmail(email: email, collection: _labCollection);

  // Nurse
  DbCollection? get _nurseCollection => MongoDatabase.userNurseCollection;

  Future<void> createNurseUser(Map<String, dynamic> data) =>
      createUser(userData: data, collection: _nurseCollection);

  Future<Map<String, dynamic>?> getNurseUserByEmail(String email) =>
      getUserByEmail(email: email, collection: _nurseCollection);

  Future<void> updateNurseUser(
          String email, Map<String, dynamic> updatedData) =>
      updateUser(
          email: email, updatedData: updatedData, collection: _nurseCollection);

  Future<void> deleteNurseUser(String email) =>
      deleteUser(email: email, collection: _nurseCollection);

  Future<List<Map<String, dynamic>>> getAllNurseUsers() =>
      getAllUsers(_nurseCollection);

  Future<bool> nurseUserExists(String email) =>
      userExists(email: email, collection: _nurseCollection);

  Future<String?> getNurseUserType(String email) =>
      getUserTypeFromMongoDB(email: email, collection: _nurseCollection);

  Future<String?> getNurseUserName(String email) =>
      getFullNameByEmail(email: email, collection: _nurseCollection);

  Future<String?> getNursePhone(String email) =>
      getPhoneNumberByEmail(email: email, collection: _nurseCollection);

  // Medical Store
  DbCollection? get _medicalStoreCollection =>
      MongoDatabase.userMedicalStoreCollection;

  Future<void> createMedicalStoreUser(Map<String, dynamic> data) =>
      createUser(userData: data, collection: _medicalStoreCollection);

  Future<Map<String, dynamic>?> getMedicalStoreUserByEmail(String email) =>
      getUserByEmail(email: email, collection: _medicalStoreCollection);

  Future<void> updateMedicalStoreUser(
          String email, Map<String, dynamic> updatedData) =>
      updateUser(
          email: email,
          updatedData: updatedData,
          collection: _medicalStoreCollection);

  Future<void> deleteMedicalStoreUser(String email) =>
      deleteUser(email: email, collection: _medicalStoreCollection);

  Future<List<Map<String, dynamic>>> getAllMedicalStoreUsers() =>
      getAllUsers(_medicalStoreCollection);

  Future<bool> medicalStoreUserExists(String email) =>
      userExists(email: email, collection: _medicalStoreCollection);

  Future<String?> getMedicalStoreUserType(String email) =>
      getUserTypeFromMongoDB(email: email, collection: _medicalStoreCollection);

  Future<String?> getMedicalStoreUserName(String email) =>
      getFullNameByEmail(email: email, collection: _medicalStoreCollection);

  Future<String?> getMedicalStorePhone(String email) =>
      getPhoneNumberByEmail(email: email, collection: _nurseCollection);

  DbCollection? get _verificationCollection => MongoDatabase.userVerification;
}
