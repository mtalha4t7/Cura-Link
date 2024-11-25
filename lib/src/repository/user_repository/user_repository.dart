import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cura_link/src/constants/text_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../../screens/features/authentication/models/user_model.dart';
import '../../shared prefrences/shared_prefrence.dart';
import '../authentication_repository/exceptions/t_exceptions.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;

  // MongoDB-related variables
  late Db mongoDb;
  late DbCollection usersCollection;

  /// Constructor to initialize the database for MongoDB
  UserRepository() {
    _initMongoDb();
  }

  /// Initialize MongoDB connection
  Future<void> _initMongoDb() async {
    try {
      mongoDb = await Db.create(MONGO_URL);
      await mongoDb.open();
      usersCollection = mongoDb
          .collection(COLLECTION_NAME); // Assuming COLLECTION_NAME is "Users"
      print('Connected to MongoDB successfully');
    } catch (e) {
      throw 'Error connecting to MongoDB: $e';
    }
  }

  // ###################### Firebase Functions ######################

  /// Store user data in Firebase
  Future<void> createUser(UserModel user) async {
    try {
      // It is recommended to use Authentication Id as DocumentId of the Users Collection.
      // To store a new user you first have to authenticate and get uID (e.g: Check Authentication Repository)
      // Add user like this: await _db.collection("Users").doc(uID).set(user.toJson());

      if (user.userType != null) {
        await saveUserType(user.userType!);
      } else {
        // Handle the case where userType is null (you might want to throw an error or provide a default value)
        throw Exception("User type is null");
      }
      await recordExist(user.email)
          ? throw "Record Already Exists"
          : await _db.collection("Users").add(user.toJson());
    } on FirebaseAuthException catch (e) {
      final result = TExceptions.fromCode(e.code);
      throw result.message;
    } on FirebaseException catch (e) {
      throw e.message.toString();
    } catch (e) {
      throw e.toString().isEmpty
          ? 'Something went wrong. Please Try Again'
          : e.toString();
    }
  }

  /// Fetch User Specific details from Firebase
  Future<UserModel> getUserDetails(String email) async {
    try {
      final snapshot =
          await _db.collection("Users").where("Email", isEqualTo: email).get();
      if (snapshot.docs.isEmpty) throw 'No such user found';

      final userData =
          snapshot.docs.map((e) => UserModel.fromSnapshot(e)).single;
      return userData;
    } on FirebaseAuthException catch (e) {
      final result = TExceptions.fromCode(e.code);
      throw result.message;
    } on FirebaseException catch (e) {
      throw e.message.toString();
    } catch (e) {
      throw e.toString().isEmpty
          ? 'Something went wrong. Please Try Again'
          : e.toString();
    }
  }

  /// Fetch All Users from Firebase
  Future<List<UserModel>> allUsers() async {
    try {
      final snapshot = await _db.collection("Users").get();
      final users =
          snapshot.docs.map((e) => UserModel.fromSnapshot(e)).toList();
      return users;
    } on FirebaseAuthException catch (e) {
      final result = TExceptions.fromCode(e.code);
      throw result.message;
    } on FirebaseException catch (e) {
      throw e.message.toString();
    } catch (_) {
      throw 'Something went wrong. Please Try Again';
    }
  }

  /// Get User's Full Name
  Future<String> getFullNameByEmail(String email) async {
    try {
      // Query Firestore to find the user document by email
      final snapshot =
          await _db.collection("Users").where("Email", isEqualTo: email).get();

      // Check if a user document exists
      if (snapshot.docs.isNotEmpty) {
        // Get the user document
        final userDoc = snapshot.docs.first;

        // Get the full name from the document
        final fullName = userDoc['FullName'];

        // Return the full name or a default message if it's not available
        return fullName ?? "No full name available";
      } else {
        return "No user found with this email"; // If no user is found
      }
    } on FirebaseAuthException catch (e) {
      final result = TExceptions.fromCode(e.code);
      throw result.message;
    } on FirebaseException catch (e) {
      throw e.message.toString();
    } catch (e) {
      throw e.toString().isEmpty
          ? 'Something went wrong. Please Try Again'
          : e.toString();
    }
  }

  Future<bool> userExistsByPhoneNumber(String phoneNumber) async {
    try {
      final snapshot = await _db
          .collection("Users")
          .where("PhoneNo", isEqualTo: phoneNumber)
          .get();

      return snapshot.docs.isNotEmpty; // Returns true if user exists
    } catch (e) {
      print("Error checking user by phone number in Firebase: $e");
      throw "Error checking user by phone number.";
    }
  }

  /// Update User details in Firebase
  Future<void> updateUserRecord(UserModel user) async {
    try {
      await _db.collection("Users").doc(user.id).update(user.toJson());
    } on FirebaseAuthException catch (e) {
      final result = TExceptions.fromCode(e.code);
      throw result.message;
    } on FirebaseException catch (e) {
      throw e.message.toString();
    } catch (_) {
      throw 'Something went wrong. Please Try Again';
    }
  }

  /// Delete User Data in Firebase
  Future<void> deleteUser(String id) async {
    try {
      await _db.collection("Users").doc(id).delete();
    } on FirebaseAuthException catch (e) {
      final result = TExceptions.fromCode(e.code);
      throw result.message;
    } on FirebaseException catch (e) {
      throw e.message.toString();
    } catch (_) {
      throw 'Something went wrong. Please Try Again';
    }
  }

  /// Check if user exists with email in Firebase
  Future<bool> recordExist(String email) async {
    try {
      final snapshot =
          await _db.collection("Users").where("Email", isEqualTo: email).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error fetching record: $e");
      throw "Error fetching record.";
    }
  }

  Future<UserModel?> getUserDetailsByPhoneNumber(String phoneNumber) async {
    try {
      final snapshot = await _db
          .collection("Users")
          .where("PhoneNo", isEqualTo: phoneNumber)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromSnapshot(
            snapshot.docs.first); // Assuming UserModel exists
      } else {
        return null; // No user found
      }
    } catch (e) {
      print("Error fetching user details by phone number in Firebase: $e");
      throw "Error fetching user details.";
    }
  }

  // ###################### MongoDB Functions ######################

  /// Store user data in MongoDB
  Future<void> mongoCreateUser(UserModel user) async {
    try {
      // Check if the users collection is empty
      final userCount = await usersCollection.count();

      if (userCount == 0) {
        // If empty, save the record
        if (user.userType == null) {
          throw 'User type is required for the first user';
        }
        await saveUserType(user.userType!);
        await usersCollection.insertOne(user.toJson());
        print('User created successfully in MongoDB as the first record');
      } else {
        // Check if the user already exists by email
        final existingUser =
            await usersCollection.findOne({"email": user.email});

        if (existingUser != null) {
          throw "Record Already Exists";
        } else {
          await usersCollection.insertOne(user.toJson());
          print('User created successfully in MongoDB');
        }
      }
    } catch (e) {
      print('Error creating user in MongoDB: $e');
      throw e.toString().isEmpty
          ? 'Something went wrong. Please try again'
          : e.toString();
    }
  }

  /// Check if user exists with phone number in MongoDB
  Future<bool> mongoUserExistsByPhoneNumber(String phoneNumber) async {
    try {
      final user = await usersCollection.findOne({"PhoneNo": phoneNumber});
      return user != null; // Returns true if user exists
    } catch (e) {
      print("Error checking user by phone number in MongoDB: $e");
      throw "Error checking user by phone number.";
    }
  }

  /// Fetch User Specific details from MongoDB
  Future<UserModel> mongoGetUserDetails(String email) async {
    try {
      final user = await usersCollection.findOne({"Email": email});
      if (user == null) throw 'No such user found';
      return UserModel.fromJson(user);
    } catch (e) {
      print('Error fetching user details in MongoDB: $e');
      throw e.toString().isEmpty
          ? 'Something went wrong. Please Try Again'
          : e.toString();
    }
  }

  /// Fetch All Users from MongoDB
  Future<List<UserModel>> mongoAllUsers() async {
    try {
      final users = await usersCollection.find().toList();
      return users.map((user) => UserModel.fromJson(user)).toList();
    } catch (e) {
      print('Error fetching all users in MongoDB: $e');
      throw 'Something went wrong. Please Try Again';
    }
  }

  /// Update User details in MongoDB
  Future<void> mongoUpdateUserRecord(UserModel user) async {
    try {
      final result = await usersCollection.updateOne(
        {"_id": ObjectId.parse(user.id!)},
        {'\$set': user.toJson()},
      );
      if (result.isFailure) throw 'Failed to update user in MongoDB';
      print('User updated successfully in MongoDB');
    } catch (e) {
      print('Error updating user in MongoDB: $e');
      throw e.toString().isEmpty
          ? 'Something went wrong. Please Try Again'
          : e.toString();
    }
  }

  Future<UserModel?> mongogetUserDetailsByPhoneNumber(
      String phoneNumber) async {
    try {
      final user = await usersCollection.findOne({"PhoneNumber": phoneNumber});
      if (user != null) {
        return UserModel.fromJson(user); // Assuming UserModel exists
      } else {
        return null; // No user found
      }
    } catch (e) {
      print("Error fetching user details by phone number in MongoDB: $e");
      throw "Error fetching user details.";
    }
  }

  /// Delete User Data in MongoDB
  Future<void> mongoDeleteUser(String id) async {
    try {
      final result =
          await usersCollection.deleteOne({"_id": ObjectId.parse(id)});
      if (result.isFailure) throw 'Failed to delete user in MongoDB';
      print('User deleted successfully in MongoDB');
    } catch (e) {
      print('Error deleting user in MongoDB: $e');
      throw e.toString().isEmpty
          ? 'Something went wrong. Please Try Again'
          : e.toString();
    }
  }

  /// Check if user exists with email in MongoDB
  Future<bool> mongoRecordExist(String email) async {
    try {
      final user = await usersCollection.findOne({"Email": email});
      return user != null;
    } catch (e) {
      print("Error checking if record exists in MongoDB: $e");
      throw "Error checking if record exists.";
    }
  }
}
