import 'dart:convert';

import 'package:flutter/material.dart';
import 'message_type.dart';

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
  final String? lastMessageFromId; // Added this field
  final int unreadCount;
  final MessageType? lastMessageType;

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
    this.lastMessageFromId, // Added this parameter
    this.unreadCount = 0,
    this.lastMessageType,
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
      'lastMessageFromId': lastMessageFromId, // Added this field
      'unreadCount': unreadCount,
      'lastMessageType': lastMessageType?.name,
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
      userLastActive: map['userLastActive']?.toString(),
      userPushToken: map['userPushToken']?.toString(),
      lastMessage: map['lastMessage']?.toString(),
      lastMessageTime: map['lastMessageTime']?.toString(),
      lastMessageFromId: map['lastMessageFromId']?.toString(), // Added this field
      unreadCount: map['unreadCount'] as int? ?? 0,
      lastMessageType: map['lastMessageType'] != null
          ? MessageType.values.firstWhere(
              (e) => e.name == map['lastMessageType'],
          orElse: () => MessageType.text)
          : null,
    );
  }

  factory ChatUserModelMongoDB.fromJson(String jsonString) {
    return ChatUserModelMongoDB.fromMap(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }
}