import 'package:flutter/material.dart';

// Renamed to MessageType to avoid conflict with MongoDB's Type
enum MessageType { text, image }

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
  final MessageType type;
  final String sent;

  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint("Parsing message: $json");

      // Handle type conversion safely
      MessageType messageType;
      if (json['type'] == 'image') {
        messageType = MessageType.image;
      } else {
        messageType = MessageType.text; // Default to text
      }

      // Handle sent timestamp conversion
      String sentTimestamp;
      if (json['sent'] is int) {
        sentTimestamp = json['sent'].toString();
      } else if (json['sent'] is String) {
        // Try parsing ISO string if needed
        try {
          DateTime.parse(json['sent']);
          sentTimestamp = json['sent'];
        } catch (e) {
          sentTimestamp = DateTime.now().millisecondsSinceEpoch.toString();
        }
      } else {
        sentTimestamp = DateTime.now().millisecondsSinceEpoch.toString();
      }

      return Message(
        toId: json['toId']?.toString() ?? "",
        msg: json['msg']?.toString() ?? "",
        read: json['read']?.toString() ?? "false",
        type: messageType,
        fromId: json['fromId']?.toString() ?? "",
        sent: sentTimestamp,
      );
    } catch (e) {
      debugPrint("Error parsing message: $e");
      // Return a default message if parsing fails
      return Message(
        toId: "",
        msg: "",
        read: "false",
        type: MessageType.text,
        fromId: "",
        sent: DateTime.now().millisecondsSinceEpoch.toString(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'toId': toId,
      'msg': msg,
      'read': read,
      'type': type.name,
      'fromId': fromId,
      'sent': sent,
    };
  }
}