import 'package:flutter/material.dart';
import 'message_type.dart';

class Message {
  final String toId;
  final String msg;
  final String read;
  final String fromId;
  final MessageType type;
  final String sent;

  Message({
    required this.toId,
    required this.msg,
    required this.read,
    required this.fromId,
    required this.type,
    required this.sent,
  });

  bool _isEmojiOnly(String text) {
    if (text.isEmpty) return false;
    final emojiRegex = RegExp(
      r'^(\p{Emoji_Presentation}|\p{Emoji}\uFE0F)+$',
      unicode: true,
    );
    return emojiRegex.hasMatch(text);
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      // Handle type conversion safely
      final typeString = json['type']?.toString().toLowerCase() ?? 'text';
      final MessageType messageType;
      switch (typeString) {
        case 'image':
          messageType = MessageType.image;
          break;
        case 'emoji':
          messageType = MessageType.emoji;
          break;
        case 'video':
          messageType = MessageType.video;
          break;
        case 'file':
          messageType = MessageType.file;
          break;
        default:
          messageType = MessageType.text;
      }

      // Handle sent timestamp conversion
      String sentTimestamp;
      if (json['sent'] is int) {
        sentTimestamp = json['sent'].toString();
      } else if (json['sent'] is String) {
        try {
          DateTime.parse(json['sent']);
          sentTimestamp = json['sent'];
        } catch (e) {
          sentTimestamp = DateTime.now().toIso8601String();
        }
      } else {
        sentTimestamp = DateTime.now().toIso8601String();
      }

      return Message(
        toId: json['toId']?.toString() ?? "",
        msg: json['msg']?.toString() ?? "",
        read: json['read']?.toString() ?? "false",
        type: messageType,
        fromId: json['fromId']?.toString() ?? "",
        sent: sentTimestamp,
      );
    } catch (e, stackTrace) {
      debugPrint("Error parsing message: $e");
      debugPrint("Stack trace: $stackTrace");
      return Message(
        toId: "",
        msg: "Error loading message",
        read: "false",
        type: MessageType.text,
        fromId: "",
        sent: DateTime.now().toIso8601String(),
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

  DateTime get sentDateTime {
    try {
      if (sent.contains(RegExp(r'^\d+$'))) {
        return DateTime.fromMillisecondsSinceEpoch(int.parse(sent));
      }
      return DateTime.parse(sent);
    } catch (e) {
      debugPrint("Error parsing sent time: $e");
      return DateTime.now();
    }
  }

  bool get isRead => read.toLowerCase() == 'true';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Message &&
              runtimeType == other.runtimeType &&
              toId == other.toId &&
              msg == other.msg &&
              read == other.read &&
              fromId == other.fromId &&
              type == other.type &&
              sent == other.sent;

  @override
  int get hashCode =>
      toId.hashCode ^
      msg.hashCode ^
      read.hashCode ^
      fromId.hashCode ^
      type.hashCode ^
      sent.hashCode;

  Message copyWith({
    String? toId,
    String? msg,
    String? read,
    String? fromId,
    MessageType? type,
    String? sent,
  }) {
    return Message(
      toId: toId ?? this.toId,
      msg: msg ?? this.msg,
      read: read ?? this.read,
      fromId: fromId ?? this.fromId,
      type: type ?? this.type,
      sent: sent ?? this.sent,
    );
  }

  @override
  String toString() {
    return 'Message{toId: $toId, msg: $msg, read: $read, fromId: $fromId, '
        'type: $type, sent: $sent}';
  }
}