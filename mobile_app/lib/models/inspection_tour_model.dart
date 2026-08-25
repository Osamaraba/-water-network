class InspectionTourPoint {
  final int pointId;
  final double latitude;
  final double longitude;
  final String? recordedAt;

  const InspectionTourPoint({
    required this.pointId,
    required this.latitude,
    required this.longitude,
    this.recordedAt,
  });

  factory InspectionTourPoint.fromJson(Map<String, dynamic> json) => InspectionTourPoint(
    pointId: json['point_id'] ?? 0,
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    recordedAt: json['recorded_at'],
  );
}

class InspectionTour {
  final int tourId;
  final int distributorId;
  final int assignedBy;
  final int recipientManagerId;
  final String? title;
  final String? notes;
  final String? scheduledAt;
  final String? startedAt;
  final String? endedAt;
  final String status;
  final String? sentAt;

  const InspectionTour({
    required this.tourId,
    required this.distributorId,
    required this.assignedBy,
    required this.recipientManagerId,
    this.title,
    this.notes,
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
    required this.status,
    this.sentAt,
  });

  factory InspectionTour.fromJson(Map<String, dynamic> json) => InspectionTour(
    tourId: json['tour_id'] ?? 0,
    distributorId: json['distributor_id'] ?? 0,
    assignedBy: json['assigned_by'] ?? 0,
    recipientManagerId: json['recipient_manager_id'] ?? 0,
    title: json['title'],
    notes: json['notes'],
    scheduledAt: json['scheduled_at'],
    startedAt: json['started_at'],
    endedAt: json['ended_at'],
    status: json['status'] ?? 'assigned',
    sentAt: json['sent_at'],
  );

  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isSent => status == 'sent';
}
