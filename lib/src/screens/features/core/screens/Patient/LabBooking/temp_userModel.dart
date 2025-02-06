class ShowLabUserModel {
  String fullName;
  String email;

  ShowLabUserModel({
    required this.fullName,
    required this.email,
  });

  factory ShowLabUserModel.fromJson(Map<String, dynamic> json) {
    return ShowLabUserModel(
      fullName: json['userName'] ?? '',
      email: json['userEmail'] ?? '',
    );
  }
}
