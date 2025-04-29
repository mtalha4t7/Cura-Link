import 'dart:convert';

class NurseModelMongoDB {
  String? userId;
  String? userName;
  String? userEmail;
  String? userPhone;
  String? userPassword;
  String? userType;
  String? userAddress;
  bool? isAvailable;

  NurseModelMongoDB({
    this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    required this.userPassword,
    this.userType,
    this.userAddress,
    this.isAvailable = false,
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
      'isAvailable': isAvailable,
    };
  }

  /// Factory constructor to create an object from a Map
  factory NurseModelMongoDB.fromDataMap(Map<String, dynamic> dataMap) {
    return NurseModelMongoDB(
      userId: dataMap['_id']?.toString(),
      userName: dataMap['userName'] as String? ?? '',
      userEmail: dataMap['userEmail'] as String? ?? '',
      userAddress: dataMap['userAddress'] as String? ?? '',
      userType: dataMap['userType'] as String? ?? 'nurse',
      userPassword: dataMap['userPassword'] as String? ?? '',
      userPhone: dataMap['userPhone'] as String? ?? '',
      isAvailable: dataMap['isAvailable'] as bool? ?? false,
    );
  }

  /// Factory constructor to create an object from JSON
  factory NurseModelMongoDB.fromJson(String datasource) {
    return NurseModelMongoDB.fromDataMap(
      json.decode(datasource) as Map<String, dynamic>,
    );
  }
}

extension NurseModelExtensions on NurseModelMongoDB {
  NurseModelMongoDB copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? userPassword,
    String? userType,
    String? userAddress,
    bool? isAvailable,
  }) {
    return NurseModelMongoDB(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      userPassword: userPassword ?? this.userPassword,
      userType: userType ?? this.userType,
      userAddress: userAddress ?? this.userAddress,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}