// utils/location_utils.dart

import 'dart:math';

class LocationUtils {
  static const double averageDeliverySpeedKmH = 30.0; // Average delivery speed in km/h
  static const double preparationTimeMinutes = 15.0; // Fixed preparation time

  // Calculate distance between two coordinates in kilometers using Haversine formula
  static double calculateDistance(lat1, lon1, lat2, lon2) {
    const r = 6371.0; // Radius of Earth in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  // Calculate estimated delivery time in minutes
  static double calculateDeliveryTime(
      double storeLat,
      double storeLon,
      double patientLat,
      double patientLon,
      ) {
    final distance = calculateDistance(storeLat, storeLon, patientLat, patientLon);
    final travelTimeMinutes = (distance / averageDeliverySpeedKmH) * 60;
    return travelTimeMinutes + preparationTimeMinutes;
  }

  // Format delivery time for display
  static String formatDeliveryTime(double minutes) {
    final totalMinutes = minutes.round();
    if (totalMinutes < 60) {
      return '$totalMinutes mins';
    } else {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      return '${hours}h ${mins}m';
    }
  }
}