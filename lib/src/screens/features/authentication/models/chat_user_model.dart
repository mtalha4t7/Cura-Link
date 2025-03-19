import 'dart:convert';
import 'dart:ffi';
import 'package:mongo_dart/mongo_dart.dart'; // Import mongo_dart for Int64

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
  String? userLastActive; // Changed to String
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
      userId: map['userId']?.toString(), // Ensure it's a String
      userName: map['userName']?.toString() ?? 'Unknown',
      userEmail: map['userEmail']?.toString() ?? 'No Email',
      userPhone: map['userPhone']?.toString(),
      userImage: map['userImage']?.toString(),
      profileImage: map['profileImage']?.toString(), // Ensure it's a String
      userAbout: map['userAbout']?.toString() ?? 'No bio available',
      userCreatedAt: map['userCreatedAt']?.toString(),
      userIsOnline: map['userIsOnline'] as bool?,
      userLastActive: map['userLastActive'] is Int64
          ? map['userLastActive'].toString() // Convert Int64 to String
          : map['userLastActive']?.toString(), // Fallback to String
      userPushToken: map['userPushToken']?.toString(),
    );
  }

  /// Factory constructor to create an object from JSON
  factory ChatUserModelMongoDB.fromJson(String jsonString) {
    return ChatUserModelMongoDB.fromMap(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }
}