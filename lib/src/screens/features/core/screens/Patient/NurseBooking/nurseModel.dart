import 'package:bson/bson.dart';

class Nurse {
  final String id;
  final String userName;
  final String userEmail;

  Nurse({
    required this.id,
    required this.userName,
    required this.userEmail,
  });

  factory Nurse.fromMap(Map<String, dynamic> map) {

    final String id = map['_id'];

    return Nurse(
      id: id,
      userName: map['userName']?.toString() ?? 'Unknown Nurse',
      userEmail: map['userEmail']?.toString() ?? '',
    );
  }
}