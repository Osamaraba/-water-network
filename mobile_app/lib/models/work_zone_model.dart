import 'package:equatable/equatable.dart';

enum ZoneType { radiusPoint, polygon }

class WorkZone extends Equatable {
  final int zoneId;
  final String zoneName;
  final ZoneType zoneType;
  final double? centerLat;
  final double? centerLng;
  final double? radiusMeters;
  final List<List<double>>? polygonPoints;
  final DateTime createdAt;

  const WorkZone({
    required this.zoneId,
    required this.zoneName,
    required this.zoneType,
    this.centerLat,
    this.centerLng,
    this.radiusMeters,
    this.polygonPoints,
    required this.createdAt,
  });

  factory WorkZone.fromJson(Map<String, dynamic> json) => WorkZone(
    zoneId: json['zone_id'],
    zoneName: json['zone_name'],
    zoneType: ZoneType.values.firstWhere(
      (e) => e.name == json['zone_type'],
      orElse: () => ZoneType.radiusPoint,
    ),
    centerLat: json['center_lat'] != null 
      ? (json['center_lat'] as num).toDouble() 
      : null,
    centerLng: json['center_lng'] != null 
      ? (json['center_lng'] as num).toDouble() 
      : null,
    radiusMeters: json['radius_meters'] != null 
      ? (json['radius_meters'] as num).toDouble() 
      : null,
    polygonPoints: json['polygon_points'] != null
      ? (json['polygon_points'] as List)
          .map((p) => [(p[0] as num).toDouble(), (p[1] as num).toDouble()])
          .toList()
      : null,
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'zone_id': zoneId,
    'zone_name': zoneName,
    'zone_type': zoneType.name,
    'center_lat': centerLat,
    'center_lng': centerLng,
    'radius_meters': radiusMeters,
    'polygon_points': polygonPoints,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [zoneId, zoneName, zoneType];
}
