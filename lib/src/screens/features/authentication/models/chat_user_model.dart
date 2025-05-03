import 'dart:convert';
import 'dart:ffi';
import 'package:mongo_dart/mongo_dart.dart';

class ChatUserModelMongoDB {
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? userImage;
  final String? profileImage;
  final String? userAbout;
  final String? userCreatedAt;
  final bool? userIsOnline;
  final String? userLastActive;
  final String? userPushToken;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;

  ChatUserModelMongoDB({
    this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    this.userImage,
    this.profileImage,
    this.userAbout,
    this.userCreatedAt,
    this.userIsOnline,
    this.userLastActive,
    this.userPushToken,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'userImage': userImage,
      'profileImage': profileImage,
      'userAbout': userAbout,
      'userCreatedAt': userCreatedAt,
      'userIsOnline': userIsOnline,
      'userLastActive': userLastActive,
      'userPushToken': userPushToken,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
    };
  }

  factory ChatUserModelMongoDB.fromMap(Map<String, dynamic> map) {
    return ChatUserModelMongoDB(
      userId: map['userId']?.toString(),
      userName: map['userName']?.toString() ?? 'Unknown',
      userEmail: map['userEmail']?.toString() ?? 'No Email',
      userPhone: map['userPhone']?.toString(),
      userImage: map['userImage']?.toString(),
      profileImage: map['profileImage']?.toString(),
      userAbout: map['userAbout']?.toString() ?? 'No bio available',
      userCreatedAt: map['userCreatedAt']?.toString(),
      userIsOnline: map['userIsOnline'] as bool?,
      userLastActive: map['userLastActive'] is Int64
          ? map['userLastActive'].toString()
          : map['userLastActive']?.toString(),
      userPushToken: map['userPushToken']?.toString(),
      lastMessage: map['lastMessage']?.toString(),
      lastMessageTime: map['lastMessageTime']?.toString(),
      unreadCount: map['unreadCount'] as int? ?? 0,
    );
  }

  factory ChatUserModelMongoDB.fromJson(String jsonString) {
    return ChatUserModelMongoDB.fromMap(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }
}