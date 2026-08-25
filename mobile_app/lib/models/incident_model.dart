class Incident {
  final int incidentId;
  final String incidentNumber;
  final String title;
  final String status;
  final String priority;
  final String? createdAt;

  const Incident({
    required this.incidentId,
    required this.incidentNumber,
    required this.title,
    required this.status,
    required this.priority,
    this.createdAt,
  });

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
    incidentId: json['incident_id'] ?? 0,
    incidentNumber: json['incident_number'] ?? '',
    title: json['title'] ?? '',
    status: json['status'] ?? 'new',
    priority: json['priority'] ?? 'medium',
    createdAt: json['created_at'],
  );
}
