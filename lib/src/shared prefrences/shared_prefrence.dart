import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveUserType(String userType) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userType', userType);
}

Future<void> saveJwtToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('jwtToken', token);
}

Future<String?> loadUserType() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userType');
}

Future<String?> loadJwtToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('jwtToken');
}
