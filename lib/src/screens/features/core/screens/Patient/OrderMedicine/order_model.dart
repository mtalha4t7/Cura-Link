class MedicalStoreOrder {
  final String id;
  final String requestId;
  final String storeId;
  final String patientId;
  final List<dynamic> medicines;
  final String? prescriptionImage;
  final String storeName;
  final String storePhone;
  final String patientName;
  final String patientLocation;
  final String status;
  final DateTime createdAt;

  MedicalStoreOrder({
    required this.id,
    required this.requestId,
    required this.storeId,
    required this.patientId,
    required this.medicines,
    required this.prescriptionImage,
    required this.storeName,
    required this.storePhone,
    required this.patientName,
    required this.patientLocation,
    required this.status,
    required this.createdAt,
  });

  factory MedicalStoreOrder.fromMap(Map<String, dynamic> map) {
    return MedicalStoreOrder(
      id: map['_id'].toString(),
      requestId: map['requestId'],
      storeId: map['storeId'],
      patientId: map['patientId'],
      medicines: List<dynamic>.from(map['medicines'] ?? []),
      prescriptionImage: map['prescriptionImage'],
      storeName: map['storeName'] ?? '',
      storePhone: map['storePhone'] ?? '',
      patientName: map['patientName'] ?? '',
      patientLocation: map['patientLocation'] ?? '',
      status: map['status'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
