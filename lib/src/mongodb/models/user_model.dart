import 'package:mongo_dart/mongo_dart.dart';

class UserModel {
  final ObjectId id;
  final String userName;
  final String userEmail;
  final String userPassword;
  final String userType;
  final String userPhone;
  final String userAddress;

  UserModel({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.userPassword,
    this.userType = '',
    this.userPhone = '',
    this.userAddress = '',
  });

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userName': userName,
      'userEmail': userEmail,
      'userPassword': userPassword,
      'userType': userType,
      'userPhone': userPhone,
      'userAddress': userAddress,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      userPassword: json['userPassword'],
      userType: json['userType'] ?? '',
      userPhone: json['userPhone'] ?? '',
      userAddress: json['userAddress'] ?? '',
    );
  }
}
