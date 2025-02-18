import 'dart:convert';

class ChatUserModelMongoDB {
  String? userId;
  String? userName;
  String? userEmail;
  String? userPhone;
  String? userImage;
  String? userAbout;
  String? userCreatedAt;
  bool? userIsOnline;
  String? userLastActive;
  String? userPushToken;

  ChatUserModelMongoDB({
    this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    this.userImage,
    this.userAbout,
    this.userCreatedAt,
    this.userIsOnline,
    this.userLastActive,
    this.userPushToken,
  });

  /// Converts the object into a Map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'userImage': userImage,
      'userAbout': userAbout,
      'userCreatedAt': userCreatedAt,
      'userIsOnline': userIsOnline,
      'userLastActive': userLastActive,
      'userPushToken': userPushToken,
    };
  }

  /// Factory constructor to create an object from a Map
  factory ChatUserModelMongoDB.fromDataMap(Map<String, dynamic> dataMap) {
    return ChatUserModelMongoDB(
      userId: dataMap['userId'] as String?,
      userName: dataMap['userName'] as String?,
      userEmail: dataMap['userEmail'] as String?,
      userPhone: dataMap['userPhone'] as String?,
      userImage: dataMap['userImage'] as String?,
      userAbout: dataMap['userAbout'] as String?,
      userCreatedAt: dataMap['userCreatedAt'] as String?,
      userIsOnline: dataMap['userIsOnline'] as bool?,
      userLastActive: dataMap['userLastActive'] as String?,
      userPushToken: dataMap['userPushToken'] as String?,
    );
  }

  /// Factory constructor to create an object from JSON
  factory ChatUserModelMongoDB.fromJson(String datasource) {
    return ChatUserModelMongoDB.fromDataMap(
      json.decode(datasource) as Map<String, dynamic>,
    );
  }
}
