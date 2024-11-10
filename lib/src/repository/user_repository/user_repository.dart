import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../screens/features/authentication/models/user_model.dart';
import '../../shared prefrences/shared_prefrence.dart';
import '../authentication_repository/exceptions/t_exceptions.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;

  /// Store user data
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
      await recordExist(user.email) ? throw "Record Already Exists" : await _db.collection("Users").add(user.toJson());
    } on FirebaseAuthException catch (e) {
      final result = TExceptions.fromCode(e.code);
      throw result.message;
    } on FirebaseException catch (e) {
      throw e.message.toString();
    } catch (e) {
      throw e.toString().isEmpty ? 'Something went wrong. Please Try Again' : e.toString();
    }
  }



  /// Fetch User Specific details
  Future<UserModel> getUserDetails(String email) async {
    try {
      // It is recommended to use Authentication Id as DocumentId of the Users Collection.
      // Then when fetching the record you only have to get user authenticationID uID and query as follows.
      // final snapshot = await _db.collection("Users").doc(uID).get();

      final snapshot = await _db.collection("Users").where("Email", isEqualTo: email).get();
      if (snapshot.docs.isEmpty) throw 'No such user found';

      // Single will throw exception if there are two entries when result return.
      // In case of multiple entries use .first to pick the first one without exception.
      final userData = snapshot.docs.map((e) => UserModel.fromSnapshot(e)).single;
      return userData;
    } on FirebaseAuthException catch (e) {
      final result = TExceptions.fromCode(e.code);
      throw result.message;
    } on FirebaseException catch (e) {
      throw e.message.toString();
    } catch (e) {
      throw e.toString().isEmpty ? 'Something went wrong. Please Try Again' : e.toString();
    }
  }

  /// Fetch All Users
  Future<List<UserModel>> allUsers() async {
    try {
      final snapshot = await _db.collection("Users").get();
      final users = snapshot.docs.map((e) => UserModel.fromSnapshot(e)).toList();
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
  Future<UserModel> getCurrentUserDetails() async {
    try {
      final uID = FirebaseAuth.instance.currentUser!.uid;
      final snapshot = await _db.collection("Users").doc(uID).get();
      if (!snapshot.exists) throw 'No such user found';
      return UserModel.fromSnapshot(snapshot);
    } on FirebaseAuthException catch (e) {
      final result = TExceptions.fromCode(e.code);
      throw result.message;
    } on FirebaseException catch (e) {
      throw e.message.toString();
    } catch (e) {
      throw e.toString().isEmpty ? 'Something went wrong. Please Try Again' : e.toString();
    }
  }

  /// Update User details
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

  /// Delete User Data
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

  /// Check if user exists with email or phoneNo
  Future<bool> recordExist(String email) async {
    try {
      final snapshot = await _db.collection("Users").where("Email", isEqualTo: email).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error fetching record: $e");
      throw "Error fetching record.";
    }
  }

}
