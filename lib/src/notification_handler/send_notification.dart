import 'dart:convert';

import 'package:http/http.dart' as http;

import 'fcmServerKey.dart';

class SendNotificationService {
  static Future<void> sendNotificationUsingApi({
    required String? token,
    required String? title,
    required String? body,
    required Map<String, dynamic>? data,
  }) async {
    String serverKey = await GetServerKey().getServerTokenKey();
    print("notification server key => ${serverKey}");
    String url =
        "https://fcm.googleapis.com/v1/projects/cura-link-36b0c/messages:send";

    var headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $serverKey',
    };

    //mesaage
    Map<String, dynamic> message = {
      "message": {
        "token": token,
        "notification": {"body": body, "title": title},
        "data": data,
      }
    };

    //hit api
    final http.Response response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print("Notification Send Successfully!");
    } else {
      print("Notification not send!");
    }
  }
}