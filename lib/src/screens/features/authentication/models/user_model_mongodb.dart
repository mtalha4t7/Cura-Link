import 'dart:convert';

class UserModelMongoDB {
  String? userId;
  String? userName;
  String? userEmail;
  String? userPhone;
  String? userPassword;
  String? userType;
  String? userAddress;
  String? userDeviceToken;

  UserModelMongoDB({
    this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    required this.userPassword,
    this.userType,
    this.userAddress,
    this.userDeviceToken
  });

  /// Converts the object into a Map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'userPassword': userPassword,
      'userType': userType,
      'userAddress': userAddress,
      'userDeviceToken':userDeviceToken
    };
  }

  /// Factory constructor to create an object from a Map

  factory UserModelMongoDB.fromDataMap(Map<String, dynamic> dataMap) {
    return UserModelMongoDB(
      userId: dataMap['_id']?.toString(), // Convert ObjectId to String
      userName: dataMap['userName'] as String?,
      userEmail: dataMap['userEmail'] as String?,
      userAddress: dataMap['userAddress'] as String?,
      userType: dataMap['userType'] as String?,
      userPassword: dataMap['userPassword'] as String?,
      userPhone: dataMap['userPhone'] as String?,
      userDeviceToken: dataMap['userDeviceToken'] as String?,
    );
  }

  /// Factory constructor to create an object from JSON
  factory UserModelMongoDB.fromJson(String datasource) {
    return UserModelMongoDB.fromDataMap(
      json.decode(datasource) as Map<String, dynamic>,
    );
  }
}
