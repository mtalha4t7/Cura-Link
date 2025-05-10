class GeoPoint {
  final String type;
  final List<double> coordinates;

  GeoPoint({required this.type, required this.coordinates});

  factory GeoPoint.fromMap(Map<String, dynamic> map) {
    return GeoPoint(
      type: map['type'] as String? ?? 'Point',
      coordinates: List<double>.from(map['coordinates']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }
}
