import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? id; // Firebase uses String for id
  final String fullName;
  final String email;
  final String phoneNo;
  final String? userType;

  /// Password should not be stored in the database.
  /// Authentication will handle login/logout.
  final String? password;

  /// Constructor
  const UserModel({
    this.id,
    required this.email,
    this.password,
    required this.fullName,
    required this.phoneNo,
    required this.userType,
  });

  /// Convert model to JSON structure (used for both Firebase and MongoDB)
  Map<String, dynamic> toJson() {
    return {
      "FullName": fullName,
      "Email": email,
      "Phone": phoneNo,
      "User-Type": userType,
    };
  }

  /// Empty Constructor for UserModel
  static UserModel empty() => const UserModel(
        id: '',
        email: '',
        fullName: '',
        phoneNo: '',
        userType: '',
      );

  /// Map a Firebase DocumentSnapshot to UserModel
  factory UserModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    // Return an empty model if the document data is null or empty.
    if (document.data() == null || document.data()!.isEmpty) {
      return UserModel.empty();
    }
    final data = document.data()!;
    return UserModel(
      id: document.id, // Firebase document ID
      email: data["Email"] ?? '',
      fullName: data["FullName"] ?? '',
      phoneNo: data["Phone"] ?? '',
      userType: data["User-Type"],
    );
  }

  /// Map JSON from MongoDB to UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["_id"]?.toString(), // Convert MongoDB ObjectId to a String
      email: json["Email"] ?? '',
      fullName: json["FullName"] ?? '',
      phoneNo: json["Phone"] ?? '',
      userType: json["User-Type"],
    );
  }
}
