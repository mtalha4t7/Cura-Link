class MedicalStoreBid {
  final String id;
  final String requestId;
  final String storeName;
  final String storeEmail;
  final double price;
  final double deliveryFee;
  final double totalPrice;
  final String deliveryTime;
  final String distance;
  final DateTime submittedAt;
  final Map<String, dynamic>? storeLocation;
  final List<dynamic>? medicines; // <-- NEW FIELD

  MedicalStoreBid({
    required this.id,
    required this.requestId,
    required this.storeName,
    required this.storeEmail,
    required this.price,
    required this.deliveryFee,
    required this.totalPrice,
    required this.deliveryTime,
    required this.distance,
    required this.submittedAt,
    this.storeLocation,
    this.medicines, // <-- NEW PARAMETER
  });

  factory MedicalStoreBid.fromMap(Map<String, dynamic> map) {
    return MedicalStoreBid(
      id: map['_id'].toString(),
      requestId: map['requestId'] ?? '',
      storeName: map['storeName'] ?? 'Unknown Store',
      storeEmail: map['storeEmail'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? (map['price'] ?? 0)).toDouble(),
      deliveryTime: map['deliveryTime'] ?? 'N/A',
      distance: map['Distance'] ?? 'N/A',
      submittedAt: DateTime.tryParse(map['submittedAt'].toString()) ?? DateTime.now(),
      storeLocation: map['storeLocation'],
      medicines: List<dynamic>.from(map['medicines'] ?? []), // <-- NEW EXTRACTION
    );
  }
}

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
