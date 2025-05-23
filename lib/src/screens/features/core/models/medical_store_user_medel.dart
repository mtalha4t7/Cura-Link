import 'dart:convert';
import '../../../../common/geo_point.dart';

class MedicalStoreModelMongoDB {
  String? userId;
  String? userName;
  String? userEmail;
  String? userPhone;
  String? userPassword;
  String? userType;
  String? userAddress;
  bool? isAvailable;
  String? userVerified;
  String? licenseNumber;
  String? storeTimings;
  double? rating;
  GeoPoint? location; // ✅ Updated to GeoPoint

  MedicalStoreModelMongoDB({
    this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    required this.userPassword,
    this.userType = 'medical_store',
    this.userAddress,
    this.isAvailable = false,
    this.userVerified = "0",
    this.licenseNumber,
    this.storeTimings,
    this.rating,
    this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'userPassword': userPassword,
      'userType': userType,
      'userAddress': userAddress,
      'isAvailable': isAvailable,
      'userVerified': userVerified,
      'licenseNumber': licenseNumber,
      'storeTimings': storeTimings,
      'rating': rating,
      'location': location?.toMap(), // ✅ serialize location
    };
  }

  factory MedicalStoreModelMongoDB.fromDataMap(Map<String, dynamic> dataMap) {
    return MedicalStoreModelMongoDB(
      userId: dataMap['_id']?.toString(),
      userName: dataMap['userName'] as String? ?? '',
      userEmail: dataMap['userEmail'] as String? ?? '',
      userAddress: dataMap['userAddress'] as String? ?? '',
      userType: dataMap['userType'] as String? ?? 'medical_store',
      userPassword: dataMap['userPassword'] as String? ?? '',
      userPhone: dataMap['userPhone'] as String? ?? '',
      isAvailable: dataMap['isAvailable'] as bool? ?? false,
      userVerified: dataMap['userVerified'] as String? ?? '0',
      licenseNumber: dataMap['licenseNumber'] as String?,
      storeTimings: dataMap['storeTimings'] as String?,
      rating: dataMap['rating'] != null
          ? double.tryParse(dataMap['rating'].toString())
          : null,
      location: dataMap['location'] != null
          ? GeoPoint.fromMap(dataMap['location'])
          : null, // ✅ deserialize location
    );
  }

  factory MedicalStoreModelMongoDB.fromJson(String datasource) {
    return MedicalStoreModelMongoDB.fromDataMap(
      json.decode(datasource) as Map<String, dynamic>,
    );
  }
}

extension MedicalStoreModelExtensions on MedicalStoreModelMongoDB {
  MedicalStoreModelMongoDB copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? userPassword,
    String? userType,
    String? userAddress,
    bool? isAvailable,
    String? userVerified,
    String? licenseNumber,
    String? storeTimings,
    double? rating,
    GeoPoint? location, // ✅ updated
  }) {
    return MedicalStoreModelMongoDB(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      userPassword: userPassword ?? this.userPassword,
      userType: userType ?? this.userType,
      userAddress: userAddress ?? this.userAddress,
      isAvailable: isAvailable ?? this.isAvailable,
      userVerified: userVerified ?? this.userVerified,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      storeTimings: storeTimings ?? this.storeTimings,
      rating: rating ?? this.rating,
      location: location ?? this.location,
    );
  }
}
