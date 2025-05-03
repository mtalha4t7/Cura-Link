import 'package:mongo_dart/mongo_dart.dart';

class PatientNurseBooking {
  ObjectId? bookingId; // MongoDB generated ID
  String nurseName;
  String patientName;
  double price;
  DateTime createdAt;

  PatientNurseBooking({
    this.bookingId,
    required this.nurseName,
    required this.patientName,
    required this.price,
    required this.createdAt,
  });

  // Convert a document from MongoDB to PatientNurseBooking
  factory PatientNurseBooking.fromMap(Map<String, dynamic> map) {
    return PatientNurseBooking(
      bookingId: map['_id'],
      nurseName: map['nurseName'],
      patientName: map['patientName'],
      price: map['price'],
      createdAt: map['createdAt'].toDate(),
    );
  }

  // Convert PatientNurseBooking to MongoDB document format
  Map<String, dynamic> toMap() {
    return {
      'nurseName': nurseName,
      'patientName': patientName,
      'price': price,
      'createdAt': createdAt,
    };
  }
}
