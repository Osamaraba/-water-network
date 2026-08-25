import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;
import '../models/work_zone_model.dart';

class GeofenceService {
  bool isInsideZone(Position position, WorkZone zone) {
    if (zone.zoneType == ZoneType.radiusPoint) {
      return _isInsideRadius(
        position.latitude, position.longitude,
        zone.centerLat!, zone.centerLng!, zone.radiusMeters!,
      );
    } else {
      return _isInsidePolygon(
        position.latitude, position.longitude, zone.polygonPoints!,
      );
    }
  }

  double? distanceToZone(Position position, WorkZone zone) {
    if (zone.zoneType == ZoneType.radiusPoint) {
      return _calculateDistance(
        position.latitude, position.longitude,
        zone.centerLat!, zone.centerLng!,
      );
    }
    return null;
  }

  bool _isInsideRadius(double lat, double lng, double centerLat, double centerLng, double radiusMeters) {
    final distance = _calculateDistance(lat, lng, centerLat, centerLng);
    return distance <= radiusMeters;
  }

  bool _isInsidePolygon(double lat, double lng, List<List<double>> polygon) {
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i][1], yi = polygon[i][0];
      final xj = polygon[j][1], yj = polygon[j][0];
      final intersect = ((yi > lng) != (yj > lng)) &&
          (lat < (xj - xi) * (lng - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
      j = i;
    }
    return inside;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a));
  }

  bool isAccuracyValid(Position position, {double maxAccuracy = 15.0}) {
    return position.accuracy <= maxAccuracy;
  }

  bool isTimestampRecent(Position position, {int maxSeconds = 15}) {
    final now = DateTime.now();
    final diff = now.difference(position.timestamp ?? now);
    return diff.inSeconds.abs() <= maxSeconds;
  }
}
