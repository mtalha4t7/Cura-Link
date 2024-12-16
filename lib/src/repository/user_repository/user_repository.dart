import 'package:cura_link/src/constants/text_strings.dart';
import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  late Db mongoDb;
  late DbCollection usersCollection;

  /// MongoDB URL and Collection Name

  /// Constructor to initialize the database connection
  UserRepository() {
    _initMongoDb();
  }

  /// Initialize MongoDB connection
  Future<void> _initMongoDb() async {
    try {
      mongoDb = await Db.create(MONGO_URL);
      await mongoDb.open();
      usersCollection = mongoDb.collection(COLLECTION_NAME);
      print('Connected to MongoDB successfully');
    } catch (e) {
      throw 'Error connecting to MongoDB: $e';
    }
  }

  /// Create a new user in MongoDB
  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      await usersCollection.insert(userData);
      print('User created successfully');
    } catch (e) {
      throw 'Error creating user: $e';
    }
  }

  /// Fetch the full name of a user by their email
  Future<String?> getFullNameByEmail(String email) async {
    try {
      // Fetch user by email
      final user = await usersCollection.findOne({'email': email});

      // Check if the user exists and return their full name
      if (user != null && user.containsKey('fullName')) {
        return user['fullName'] as String;
      } else {
        return null; // Return null if no user or fullName field is found
      }
    } catch (e) {
      throw 'Error fetching full name: $e';
    }
  }

  /// Fetch a user by their email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final user = await usersCollection.findOne({'email': email});
      return user;
    } catch (e) {
      throw 'Error fetching user: $e';
    }
  }

  /// Update user details by their email
  Future<void> updateUser(
      String email, Map<String, dynamic> updatedData) async {
    try {
      await usersCollection.update(
        {'email': email},
        {'\$set': updatedData},
      );
      print('User updated successfully');
    } catch (e) {
      throw 'Error updating user: $e';
    }
  }

  /// Delete a user by their email
  Future<void> deleteUser(String email) async {
    try {
      await usersCollection.remove({'email': email});
      print('User deleted successfully');
    } catch (e) {
      throw 'Error deleting user: $e';
    }
  }

  /// Get all users from MongoDB
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final users = await usersCollection.find().toList();
      return users;
    } catch (e) {
      throw 'Error fetching users: $e';
    }
  }

  /// Check if a user exists by their email
  Future<bool> userExists(String email) async {
    try {
      final user = await usersCollection.findOne({'email': email});
      return user != null;
    } catch (e) {
      throw 'Error checking if user exists: $e';
    }
  }

  /// Close the MongoDB connection
  Future<void> closeConnection() async {
    try {
      await mongoDb.close();
      print('MongoDB connection closed');
    } catch (e) {
      throw 'Error closing MongoDB connection: $e';
    }
  }
}
