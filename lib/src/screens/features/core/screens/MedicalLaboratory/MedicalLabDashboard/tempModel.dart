class UserVerifiedModel {
  final String? id; // Firebase uses String for id
  final String? userVerified;

  /// Constructor
  const UserVerifiedModel({
    this.id,
    this.userVerified,
  });

  /// Convert model to JSON structure (used for both Firebase and MongoDB)
  Map<String, dynamic> toJson() {
    return {
      "User-Verified": userVerified,
    };
  }

  /// Empty Constructor for UserVerifiedModel
  static UserVerifiedModel empty() => const UserVerifiedModel(
        id: '',
        userVerified: '',
      );

  /// Map JSON from MongoDB to UserVerifiedModel
  factory UserVerifiedModel.fromJson(Map<String, dynamic> json) {
    return UserVerifiedModel(
      id: json["_id"]?.toString(), // Convert MongoDB ObjectId to a String
      userVerified: json["User-Verified"],
    );
  }
}