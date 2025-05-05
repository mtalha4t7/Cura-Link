class MedicalStoreRequest {
  final String id;
  final String patientEmail;
  final List<MedicineItem> medicines;
  final String? prescriptionImageUrl;
  final String deliveryAddress;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String status;
  final DateTime createdAt;

  MedicalStoreRequest({
    required this.id,
    required this.patientEmail,
    required this.medicines,
    this.prescriptionImageUrl,
    required this.deliveryAddress,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory MedicalStoreRequest.fromMap(Map<String, dynamic> map) {
    return MedicalStoreRequest(
      id: map['_id'].toString(),
      patientEmail: map['patientEmail'],
      medicines: (map['medicines'] as List).map((m) => MedicineItem.fromMap(m)).toList(),
      prescriptionImageUrl: map['prescriptionImage'],
      deliveryAddress: map['deliveryAddress'],
      subtotal: map['subtotal'].toDouble(),
      deliveryFee: map['deliveryFee'].toDouble(),
      total: map['total'].toDouble(),
      status: map['status'],
      createdAt: map['createdAt'],
    );
  }
}

class MedicineItem {
  final String name;
  final double price;
  final int quantity;
  final String category;

  MedicineItem({
    required this.name,
    required this.price,
    required this.category,
    this.quantity = 1,
  });

  factory MedicineItem.fromMap(Map<String, dynamic> map) {
    return MedicineItem(
      name: map['name'],
      price: map['price'].toDouble(),
      quantity: map['quantity'] ?? 1,
      category: map['category'],
    );
  }
}

class MedicalStoreBid {
  final String id;
  final String requestId;
  final String storeName;
  final String storeEmail;
  final double originalAmount;
  final double bidAmount;
  final String status;
  final double storeRating; // <-- New field
  final DateTime createdAt;

  MedicalStoreBid({
    required this.id,
    required this.requestId,
    required this.storeEmail,
    required this.storeName,
    required this.originalAmount,
    required this.bidAmount,
    required this.status,
    required this.storeRating, // <-- Include in constructor
    required this.createdAt,
  });

  factory MedicalStoreBid.fromMap(Map<String, dynamic> map) {
    return MedicalStoreBid(
      id: map['_id'].toString(),
      requestId: map['requestId'] ?? '',
      storeName: map['storeName'] ?? 'Unknown Store',
      storeEmail: map['storeEmail'] ?? '',
      originalAmount: (map['originalAmount'] ?? map['price'] ?? 0).toDouble(),
      bidAmount: (map['bidAmount'] ?? map['price'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      storeRating: (map['storeRating'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now(),
    );
  }

}

