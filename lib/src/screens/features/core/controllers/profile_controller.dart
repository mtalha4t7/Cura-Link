import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../../../../constants/text_strings.dart';
import '../../../../mongodb/mongodb.dart';
import '../../../../repository/authentication_repository/authentication_repository.dart';
import '../../../../repository/user_repository/user_repository.dart';
import '../../../../utils/helper/helper_controller.dart';
import '../../authentication/models/user_model.dart';

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();

  /// Repositories
  final _authRepo = AuthenticationRepository.instance;
  final _userRepo = UserRepository.instance;

  /// Get User Email and pass to UserRepository to fetch user record.
  Future<UserModel?> getUserData() async {
    try {
      final currentUserEmail = _authRepo.getUserEmail;
      if (currentUserEmail.isNotEmpty) {
        final userData = await _userRepo.getUserByEmail(currentUserEmail);
        if (userData != null) {
          return UserModel.fromJson(userData);
        } else {
          Helper.warningSnackBar(
              title: 'Error', message: 'No user data found!');
          return null;
        }
      } else {
        Helper.warningSnackBar(title: 'Error', message: 'No user found!');
        return null;
      }
    } catch (e) {
      Helper.errorSnackBar(title: 'Error', message: e.toString());
      return null;
    }
  }

  /// Fetch List of user records.
  Future<List<UserModel>> getAllUsers() async {
    try {
      final users = await _userRepo.getAllUsers();
      return users.map((user) => UserModel.fromJson(user)).toList();
    } catch (e) {
      Helper.errorSnackBar(title: 'Error', message: e.toString());
      return [];
    }
  }

  /// Update User Data
  Future<void> updateRecord(UserModel user) async {
    try {
      await _userRepo.updateUser(user.email, user.toJson());
      Helper.successSnackBar(
          title: tCongratulations, message: 'Profile record has been updated!');
    } catch (e) {
      Helper.errorSnackBar(title: 'Error', message: e.toString());
    }
  }
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

  /// Delete User
  Future<void> deleteUser() async {
    try {
      final currentUserEmail = _authRepo.getUserEmail;
      if (currentUserEmail.isNotEmpty) {
        await _userRepo.deleteUser(currentUserEmail);
        Helper.successSnackBar(
            title: tCongratulations, message: 'Account has been deleted!');
        // Optionally, you can log out the user or redirect to another screen here.
        _authRepo.logout;
      } else {
        Helper.warningSnackBar(
            title: 'Error', message: 'User cannot be deleted!');
      }
    } catch (e) {
      Helper.errorSnackBar(title: 'Error', message: e.toString());
    }
  }
}
