import 'package:flutter/material.dart';

class Message {
  Message({
    required this.toId,
    required this.msg,
    required this.read,
    required this.type,
    required this.fromId,
    required this.sent,
  });

  final String toId;
  final String msg;
  final String read;
  final String fromId;
  final Type type;
  final String sent; // Can be int (timestamp) or String (ISO date)

  /// ✅ Fix: Improved fromJson method
  factory Message.fromJson(Map<String, dynamic> json) {
    debugPrint("Parsing message: $json"); // Log incoming JSON

    return Message(
      toId: json['toId']?.toString() ?? "",
      msg: json['msg']?.toString() ?? "",
      read: json['read']?.toString() ?? "",
      type: json['type'] == Type.image.name ? Type.image : Type.text,
      fromId: json['fromId']?.toString() ?? "",
      sent: json['sent'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['sent'])
              .toString() // Convert int timestamp to String
          : json['sent']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toId': toId,
      'msg': msg,
      'read': read,
      'type': type.name,
      'fromId': fromId,
      'sent': sent, // Store timestamp correctly
    };
  }
}

enum Type { text, image }
