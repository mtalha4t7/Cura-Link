import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? id;
  final String fullName;
  final String email;
  final String phoneNo;
  final String? userType;

  /// Password should not be stored in the database.
  /// Authentication will handle login logout for us.
  /// So just use this variable to get data from user and pass it to authentication.
  final String? password;

  /// Constructor
  const UserModel(
      {this.id,
      required this.email,
      this.password,
      required this.fullName,
      required this.phoneNo,
      required this.userType});

  /// convert model to Json structure so that you can use it to store data in Firebase
  toJson() {
    return {
      "FullName": fullName,
      "Email": email,
      "Phone": phoneNo,
      "User-Type": userType,
    };
  }

  /// Empty Constructor for UserModel
  static UserModel empty() => const UserModel(
      id: '', email: '', fullName: '', phoneNo: '', userType: '');

  /// Map Json oriented document snapshot from Firebase to UserModel
  factory UserModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    // If document is empty then return an empty Model as created above.
    if (document.data() == null || document.data()!.isEmpty)
      return UserModel.empty();
    final data = document.data()!;
    return UserModel(
        id: document.id,
        email: data["Email"] ?? '',
        fullName: data["Name"] ?? '',
        phoneNo: data["Phone"] ?? '',
        userType: data["User-Type"]);
  }
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["_id"]
          ?.toString(), // MongoDB typically uses an ObjectId for the id
      email: json["Email"] ?? '',
      fullName: json["FullName"] ?? '',
      phoneNo: json["Phone"] ?? '',
      userType: json["User-Type"],
    );
  }
}
