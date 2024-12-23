import 'package:shared_preferences/shared_preferences.dart';

/// Save user type to SharedPreferences
Future<void> saveUserType(String userType) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userType', userType);
}

/// Load user type from SharedPreferences
Future<String?> loadUserType() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userType');
}

/// Save JWT token to SharedPreferences
Future<void> saveJwtToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('jwtToken', token);
}

/// Load JWT token from SharedPreferences
Future<String?> loadJwtToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('jwtToken');
}

/// Save user details to SharedPreferences
Future<void> saveUserDetails(Map<String, dynamic> userDetails) async {
  final prefs = await SharedPreferences.getInstance();

  // Save user details individually
  await prefs.setString('userEmail', userDetails['userEmail'] ?? '');
  await prefs.setString('fullName', userDetails['fullName'] ?? '');
  await prefs.setString('userType', userDetails['userType'] ?? '');
  await prefs.setString('phoneNumber', userDetails['phoneNumber'] ?? '');
}

/// Load user details from SharedPreferences
Future<Map<String, String>> loadUserDetails() async {
  final prefs = await SharedPreferences.getInstance();

  // Retrieve user details
  return {
    'userEmail': prefs.getString('userEmail') ?? '',
    'fullName': prefs.getString('fullName') ?? '',
    'userType': prefs.getString('userType') ?? '',
    'phoneNumber': prefs.getString('phoneNumber') ?? '',
  };
}

/// Fetch user details from the repository and save them locally

Future<void> saveServicesToPreferences(List<String> services) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('testServices', services);
}

Future<List<String>> getServicesFromPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList('testServices') ?? [];
}
