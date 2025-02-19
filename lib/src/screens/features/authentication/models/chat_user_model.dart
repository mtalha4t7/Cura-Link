import 'dart:convert';

class ChatUserModelMongoDB {
  String? userId;
  String? userName;
  String? userEmail;
  String? userPhone;
  String? userImage;
  String? profileImage; // New data member added
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
    this.profileImage, // Added in constructor
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
      'profileImage': profileImage, // Added in toJson method
      'userAbout': userAbout,
      'userCreatedAt': userCreatedAt,
      'userIsOnline': userIsOnline,
      'userLastActive': userLastActive,
      'userPushToken': userPushToken,
    };
  }

  /// Factory constructor to create an object from a Map
  factory ChatUserModelMongoDB.fromMap(Map<String, dynamic> map) {
    return ChatUserModelMongoDB(
      userId: map['userId'] as String?,
      userName: map['userName'] as String? ?? 'Unknown',
      userEmail: map['userEmail'] as String? ?? 'No Email',
      userPhone: map['userPhone'] as String?,
      userImage: map['userImage'] as String?,
      profileImage: map['profileImage'] as String?, // Added in fromMap method
      userAbout: map['userAbout'] as String? ?? 'No bio available',
      userCreatedAt: map['userCreatedAt'] as String?,
      userIsOnline: map['userIsOnline'] as bool?,
      userLastActive: map['userLastActive'] as String?,
      userPushToken: map['userPushToken'] as String?,
    );
  }

  /// Factory constructor to create an object from JSON
  factory ChatUserModelMongoDB.fromJson(String jsonString) {
    return ChatUserModelMongoDB.fromMap(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }
}
