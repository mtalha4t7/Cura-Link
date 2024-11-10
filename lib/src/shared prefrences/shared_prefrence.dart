import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveUserType(String userType) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userType', userType);
}

Future<String?> loadUserType() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userType');
}
