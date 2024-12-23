import 'package:cura_link/src/shared%20prefrences/shared_prefrence.dart';
import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../../../../../../constants/text_strings.dart';
import '../../../../../../mongodb/mongodb.dart';
import '../../../../../../repository/authentication_repository/authentication_repository.dart';
import '../../../../../../repository/user_repository/user_repository.dart';
import '../../../../../../utils/helper/helper_controller.dart';
import '../../../../authentication/models/user_model.dart';

class MedicalLabProfileController extends GetxController {
  static MedicalLabProfileController get instance => Get.find();

  /// Repositories
  final _authRepo = AuthenticationRepository.instance;
  final _userRepo = UserRepository.instance;

  /// Get User Email and pass to UserRepository to fetch user record.

  Future<List<UserModel>> getAllUsers() async {
    try {
      // Fetching all users from the collection (could be combined if using a single collection).
      final nurseCollection =
          await _userRepo.getAllUsers(MongoDatabase.userLabCollection);
      final patientCollection =
          await _userRepo.getAllUsers(MongoDatabase.userLabCollection);
      final labCollection =
          await _userRepo.getAllUsers(MongoDatabase.userLabCollection);
      final medicalStoreCollection =
          await _userRepo.getAllUsers(MongoDatabase.userLabCollection);

      // Combine all user lists into one collection.
      List<UserModel> allUsers = [
        ...nurseCollection.map((user) => UserModel.fromJson(user)),
        ...patientCollection.map((user) => UserModel.fromJson(user)),
        ...labCollection.map((user) => UserModel.fromJson(user)),
        ...medicalStoreCollection.map((user) => UserModel.fromJson(user)),
      ];
      return allUsers; // Return the combined list of users.
    } catch (e) {
      Helper.errorSnackBar(title: 'Error', message: e.toString());
      return [];
    }
  }

  /// Update User Data
  Future<void> updateRecord(UserModel user) async {
    try {
      String? userType = await loadUserType();
      if (userType == "Patient") {
        await _userRepo.updatePatient(user.email, user.toJson());
      } else if (userType == "Lab") {
        await _userRepo.updateLabUser(user.email, user.toJson());
      } else if (userType == "Medical-Store") {
        await _userRepo.updateMedicalStoreUser(user.email, user.toJson());
      } else if (userType == "Nurse") {
        await _userRepo.updateNurseUser(user.email, user.toJson());
      }

      Helper.successSnackBar(
          title: tCongratulations, message: 'Profile record has been updated!');
    } catch (e) {
      Helper.errorSnackBar(title: 'Error', message: e.toString());
    }
  }

  Future<void> updateUserFields(
      String email, Map<String, dynamic> fieldsToUpdate) async {
    try {
      final query = {'userEmail': email};
      final modifyBuilder = ModifierBuilder();

      // Add each field to the ModifierBuilder
      fieldsToUpdate.forEach((key, value) {
        modifyBuilder.set(key, value);
      });

      // Await the userType since loadUserType() returns a Future
      String? userType = await loadUserType();

      if (userType == null) {
        throw 'User type is null. Unable to proceed with the update.';
      }

      // Define the result variable
      late WriteResult? result;

      // Choose the correct collection based on the userType
      switch (userType) {
        case "Patient":
          result = await MongoDatabase.userPatientCollection?.updateOne(
            query,
            modifyBuilder,
          );
          break;

        case "Lab":
          result = await MongoDatabase.userLabCollection?.updateOne(
            query,
            modifyBuilder,
          );
          break;

        case "Medical-Store":
          result = await MongoDatabase.userMedicalStoreCollection?.updateOne(
            query,
            modifyBuilder,
          );
          break;

        case "Nurse":
          result = await MongoDatabase.userNurseCollection?.updateOne(
            query,
            modifyBuilder,
          );
          break;

        default:
          throw 'Invalid user type: $userType';
      }

      // Check the update result
      if (result?.nMatched == 0) {
        print('No document matched the given email.');
      } else if (result?.nModified == 0) {
        print(
            'The document was matched, but no modification was made (fields might be the same).');
      } else {
        print('User fields updated successfully.');
      }
    } catch (e) {
      print('Error updating user fields: $e');
      throw 'Error updating user fields: $e';
    }
  }
}
