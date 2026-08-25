class Departure {
  final int departureId;
  final int? employeeId;
  final String departureType; // 'official' | 'personal'
  final String? departureTime;
  final String? returnTime;
  final String? reason;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? reviewNote;
  final String? employeeName;
  final String? employeeNumber;
  final String? createdAt;

  const Departure({
    required this.departureId,
    this.employeeId,
    required this.departureType,
    this.departureTime,
    this.returnTime,
    this.reason,
    required this.status,
    this.reviewNote,
    this.employeeName,
    this.employeeNumber,
    this.createdAt,
  });

  factory Departure.fromJson(Map<String, dynamic> j) => Departure(
        departureId: j['departure_id'],
        employeeId: j['employee_id'],
        departureType: j['departure_type'] ?? '',
        departureTime: j['departure_time'],
        returnTime: j['return_time'],
        reason: j['reason'],
        status: j['status'] ?? 'pending',
        reviewNote: j['review_note'],
        employeeName: j['employee_name'],
        employeeNumber: j['employee_number'],
        createdAt: j['created_at'],
      );

  String get typeLabel => departureType == 'official' ? 'رسمية' : 'خاصة';

  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'معتمدة';
      case 'rejected':
        return 'مرفوضة';
      default:
        return 'بانتظار الموافقة';
    }
  }
}
