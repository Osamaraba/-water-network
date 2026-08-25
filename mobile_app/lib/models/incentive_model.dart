class Incentive {
  final int incentiveId;
  final int employeeId;
  final String periodStart;
  final String periodEnd;
  final double? avgSpeed;
  final double? avgAccuracy;
  final double? performanceScore;
  final double? incentiveAmount;
  final String status;
  final int? reviewedBy;
  final String? reviewedAt;

  const Incentive({
    required this.incentiveId,
    required this.employeeId,
    required this.periodStart,
    required this.periodEnd,
    this.avgSpeed,
    this.avgAccuracy,
    this.performanceScore,
    this.incentiveAmount,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory Incentive.fromJson(Map<String, dynamic> json) => Incentive(
    incentiveId: json['incentive_id'] ?? 0,
    employeeId: json['employee_id'] ?? 0,
    periodStart: json['period_start'] ?? '',
    periodEnd: json['period_end'] ?? '',
    avgSpeed: (json['avg_speed'] as num?)?.toDouble(),
    avgAccuracy: (json['avg_accuracy'] as num?)?.toDouble(),
    performanceScore: (json['performance_score'] as num?)?.toDouble(),
    incentiveAmount: (json['incentive_amount'] as num?)?.toDouble(),
    status: json['status'] ?? 'pending',
    reviewedBy: json['reviewed_by'],
    reviewedAt: json['reviewed_at'],
  );

  Map<String, dynamic> toJson() => {
    'incentive_id': incentiveId,
    'employee_id': employeeId,
    'period_start': periodStart,
    'period_end': periodEnd,
    'avg_speed': avgSpeed,
    'avg_accuracy': avgAccuracy,
    'performance_score': performanceScore,
    'incentive_amount': incentiveAmount,
    'status': status,
    'reviewed_by': reviewedBy,
    'reviewed_at': reviewedAt,
  };
}
