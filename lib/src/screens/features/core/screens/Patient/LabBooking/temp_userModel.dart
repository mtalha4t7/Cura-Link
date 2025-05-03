class ShowLabUserModel {
  final String id;
  final String userEmail;
  final String userPassword;
  final String userName;
  final String userPhone;
  final String userAddress;
  final String userType;
  final String userId;
  final String userVerified;
  final String profileImage;

  ShowLabUserModel({
    required this.id,
    required this.userEmail,
    required this.userPassword,
    required this.userName,
    required this.userPhone,
    required this.userAddress,
    required this.userType,
    required this.userId,
    required this.userVerified,
    required this.profileImage,
  });

  factory ShowLabUserModel.fromJson(Map<String, dynamic> json) {
    return ShowLabUserModel(
      id: json['_id'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userPassword: json['userPassword'] ?? '',
      userName: json['userName'] ?? '',
      userPhone: json['userPhone'] ?? '',
      userAddress: json['userAddress'] ?? '',
      userType: json['userType'] ?? '',
      userId: json['userId'] ?? '',
      userVerified: json['userVerified'] ?? '',
      profileImage: json['profileImage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userEmail': userEmail,
      'userPassword': userPassword,
      'userName': userName,
      'userPhone': userPhone,
      'userAddress': userAddress,
      'userType': userType,
      'userId': userId,
      'userVerified': userVerified,
      'profileImage': profileImage,
    };
  }
}
