class MedicalStoreBid {
  final String id;
  final String storeName;
  final String storeEmail;
  final double bidAmount;
  final double originalAmount;
  final double? storeRating;

  MedicalStoreBid({
    required this.id,
    required this.storeName,
    required this.storeEmail,
    required this.bidAmount,
    required this.originalAmount,
    this.storeRating,
  });

  factory MedicalStoreBid.fromMap(Map<String, dynamic> map) {
    return MedicalStoreBid(
      id: map['_id'].toString(),
      storeName: map['storeName'] ?? 'Unknown Store',
      storeEmail: map['storeEmail'] ?? '',
      bidAmount: (map['price'] ?? 0.0).toDouble(),
      originalAmount: (map['originalAmount'] ?? map['price'] ?? 0.0).toDouble(),
      storeRating: map['storeRating']?.toDouble(),
    );
  }
}