import 'package:equatable/equatable.dart';

class AttendanceLog extends Equatable {
  final int? logId;
  final int employeeId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double checkInLat;
  final double checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;
  final String? checkInImagePath;
  final String? checkOutImagePath;
  final bool isOfflineSync;
  final double overtimeApprovedHours;
  final bool? isMockLocationDetected;
  final double? gpsAccuracyMeters;
  final String? imageHash;
  final String? transactionId;
  final double? overtimeHours;
  final int? trustScore;
  final String? trustStatus;

  const AttendanceLog({
    this.logId,
    required this.employeeId,
    required this.checkInTime,
    this.checkOutTime,
    required this.checkInLat,
    required this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    this.checkInImagePath,
    this.checkOutImagePath,
    this.isOfflineSync = false,
    this.overtimeApprovedHours = 0.0,
    this.isMockLocationDetected,
    this.gpsAccuracyMeters,
    this.imageHash,
    this.transactionId,
    this.overtimeHours,
    this.trustScore,
    this.trustStatus,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) => AttendanceLog(
    logId: json['log_id'],
    employeeId: json['employee_id'],
    checkInTime: DateTime.parse(json['check_in_time']),
    checkOutTime: json['check_out_time'] != null 
      ? DateTime.parse(json['check_out_time']) 
      : null,
    checkInLat: (json['check_in_lat'] as num).toDouble(),
    checkInLng: (json['check_in_lng'] as num).toDouble(),
    checkOutLat: json['check_out_lat'] != null 
      ? (json['check_out_lat'] as num).toDouble() 
      : null,
    checkOutLng: json['check_out_lng'] != null 
      ? (json['check_out_lng'] as num).toDouble() 
      : null,
    checkInImagePath: json['check_in_image_path'],
    checkOutImagePath: json['check_out_image_path'],
    isOfflineSync: json['is_offline_sync'] ?? false,
    overtimeApprovedHours: (json['overtime_approved_hours'] ?? 0.0).toDouble(),
    isMockLocationDetected: json['is_mock_location_detected'],
    gpsAccuracyMeters: json['gps_accuracy_meters'] != null 
      ? (json['gps_accuracy_meters'] as num).toDouble() 
      : null,
    imageHash: json['image_hash'],
    transactionId: json['transaction_id'],
    overtimeHours: json['overtime_hours'] != null
        ? (json['overtime_hours'] as num).toDouble()
        : null,
    trustScore: json['trust_score'] != null ? json['trust_score'] as int : null,
    trustStatus: json['trust_status'],
  );

  Map<String, dynamic> toJson() => {
    'log_id': logId,
    'employee_id': employeeId,
    'check_in_time': checkInTime.toIso8601String(),
    'check_out_time': checkOutTime?.toIso8601String(),
    'check_in_lat': checkInLat,
    'check_in_lng': checkInLng,
    'check_out_lat': checkOutLat,
    'check_out_lng': checkOutLng,
    'check_in_image_path': checkInImagePath,
    'check_out_image_path': checkOutImagePath,
    'is_offline_sync': isOfflineSync,
    'overtime_approved_hours': overtimeApprovedHours,
    'is_mock_location_detected': isMockLocationDetected,
    'gps_accuracy_meters': gpsAccuracyMeters,
    'image_hash': imageHash,
    'transaction_id': transactionId,
    'overtime_hours': overtimeHours,
    'trust_score': trustScore,
    'trust_status': trustStatus,
  };

  AttendanceLog copyWith({
    int? logId,
    int? employeeId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? checkInLat,
    double? checkInLng,
    double? checkOutLat,
    double? checkOutLng,
    String? checkInImagePath,
    String? checkOutImagePath,
    bool? isOfflineSync,
    double? overtimeApprovedHours,
    bool? isMockLocationDetected,
    double? gpsAccuracyMeters,
    String? imageHash,
    String? transactionId,
    double? overtimeHours,
    int? trustScore,
    String? trustStatus,
  }) => AttendanceLog(
    logId: logId ?? this.logId,
    employeeId: employeeId ?? this.employeeId,
    checkInTime: checkInTime ?? this.checkInTime,
    checkOutTime: checkOutTime ?? this.checkOutTime,
    checkInLat: checkInLat ?? this.checkInLat,
    checkInLng: checkInLng ?? this.checkInLng,
    checkOutLat: checkOutLat ?? this.checkOutLat,
    checkOutLng: checkOutLng ?? this.checkOutLng,
    checkInImagePath: checkInImagePath ?? this.checkInImagePath,
    checkOutImagePath: checkOutImagePath ?? this.checkOutImagePath,
    isOfflineSync: isOfflineSync ?? this.isOfflineSync,
    overtimeApprovedHours: overtimeApprovedHours ?? this.overtimeApprovedHours,
    isMockLocationDetected: isMockLocationDetected ?? this.isMockLocationDetected,
    gpsAccuracyMeters: gpsAccuracyMeters ?? this.gpsAccuracyMeters,
    imageHash: imageHash ?? this.imageHash,
    transactionId: transactionId ?? this.transactionId,
    overtimeHours: overtimeHours ?? this.overtimeHours,
    trustScore: trustScore ?? this.trustScore,
    trustStatus: trustStatus ?? this.trustStatus,
  );

  @override
  List<Object?> get props => [logId, employeeId, checkInTime, checkOutTime];
}
