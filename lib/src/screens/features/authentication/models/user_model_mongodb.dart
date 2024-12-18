import 'dart:convert';

class UserModelMongoDB {
  String? userId;
  String? userName;
  String? userEmail;
  String? userPhone;
  String? userPassword;
  String? userType;
  String? userAddress;

  UserModelMongoDB({
    this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    required this.userPassword,
    this.userType,
    this.userAddress,
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
    };
  }

  /// Factory constructor to create an object from a Map
  factory UserModelMongoDB.fromDataMap(Map<String, dynamic> dataMap) {
    return UserModelMongoDB(
      userId: dataMap['userId'] as String?,
      userName: dataMap['userName'] as String?,
      userEmail: dataMap['userEmail'] as String?,
      userAddress: dataMap['userAddress'] as String?,
      userType: dataMap['userType'] as String?,
      userPassword: dataMap['userPassword'] as String?,
      userPhone: dataMap['userPhone'] as String?,
    );
  }

  /// Factory constructor to create an object from JSON
  factory UserModelMongoDB.fromJson(String datasource) {
    return UserModelMongoDB.fromDataMap(
      json.decode(datasource) as Map<String, dynamic>,
    );
  }
}
