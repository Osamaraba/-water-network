class PerformanceEvaluation {
  final int evaluationId;
  final int evaluatorId;
  final int employeeId;
  final int? taskReportId;
  final int speedScore;
  final int accuracyScore;
  final String? comment;
  final String? createdAt;

  const PerformanceEvaluation({
    required this.evaluationId,
    required this.evaluatorId,
    required this.employeeId,
    this.taskReportId,
    required this.speedScore,
    required this.accuracyScore,
    this.comment,
    this.createdAt,
  });

  factory PerformanceEvaluation.fromJson(Map<String, dynamic> json) => PerformanceEvaluation(
    evaluationId: json['evaluation_id'] ?? 0,
    evaluatorId: json['evaluator_id'] ?? 0,
    employeeId: json['employee_id'] ?? 0,
    taskReportId: json['task_report_id'],
    speedScore: json['speed_score'] ?? 0,
    accuracyScore: json['accuracy_score'] ?? 0,
    comment: json['comment'],
    createdAt: json['created_at'],
  );

  Map<String, dynamic> toJson() => {
    'evaluation_id': evaluationId,
    'evaluator_id': evaluatorId,
    'employee_id': employeeId,
    'task_report_id': taskReportId,
    'speed_score': speedScore,
    'accuracy_score': accuracyScore,
    'comment': comment,
    'created_at': createdAt,
  };
}
