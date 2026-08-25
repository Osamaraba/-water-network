import 'package:equatable/equatable.dart';

class GpsTelemetry extends Equatable {
  final int? telemetryId;
  final int employeeId;
  final double latitude;
  final double longitude;
  final double? speed;
  final DateTime recordedAt;
  final bool isSynced;

  const GpsTelemetry({
    this.telemetryId,
    required this.employeeId,
    required this.latitude,
    required this.longitude,
    this.speed,
    required this.recordedAt,
    this.isSynced = false,
  });

  factory GpsTelemetry.fromJson(Map<String, dynamic> json) => GpsTelemetry(
    telemetryId: json['telemetry_id'],
    employeeId: json['employee_id'],
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
    recordedAt: DateTime.parse(json['recorded_at']),
    isSynced: json['is_synced'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'telemetry_id': telemetryId,
    'employee_id': employeeId,
    'latitude': latitude,
    'longitude': longitude,
    'speed': speed,
    'recorded_at': recordedAt.toIso8601String(),
    'is_synced': isSynced,
  };

  @override
  List<Object?> get props => [telemetryId, employeeId, latitude, longitude, recordedAt];
}
