import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/gps_telemetry_model.dart';
import '../models/attendance_model.dart';
import 'auth_service.dart';

class ApiService {
  // Point this at the backend API. For local Android emulator use http://10.0.2.2:8000
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.yarmouk-water.jo/v1',
  );

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // Demo mode: when true, data calls return local mock data (no backend needed).
  static bool demoMode = false;

  static const List<Map<String, dynamic>> _mockEmployees = [
    {'employee_id': 1, 'full_name': 'مشرف النظام', 'username': 'admin', 'role_name': 'مشرف النظام', 'department': 'الإدارة', 'is_active': true},
    {'employee_id': 11, 'full_name': 'أحمد الفني', 'username': 'tech1', 'role_name': 'فني صيانة', 'department': 'الصيانة', 'is_active': true},
    {'employee_id': 12, 'full_name': 'خالد الموزع', 'username': 'dist1', 'role_name': 'موزع مياه', 'department': 'التوزيع', 'is_active': true},
    {'employee_id': 13, 'full_name': 'سامي العامل', 'username': 'sew1', 'role_name': 'عامل صرف صحي', 'department': 'الصرف الصحي', 'is_active': true},
    {'employee_id': 14, 'full_name': 'محمد المحصل', 'username': 'col1', 'role_name': 'محصل', 'department': 'التحصيل', 'is_active': true},
    {'employee_id': 3, 'full_name': 'سارة الموارد', 'username': 'hr1', 'role_name': 'مدير الموارد البشرية', 'department': 'الموارد البشرية', 'is_active': true},
  ];

  static const List<Map<String, dynamic>> _mockLive = [
    {'employee_id': 11, 'full_name': 'أحمد الفني', 'latitude': 32.551, 'longitude': 35.851},
    {'employee_id': 12, 'full_name': 'خالد الموزع', 'latitude': 32.559, 'longitude': 35.847},
    {'employee_id': 13, 'full_name': 'سامي العامل', 'latitude': 32.545, 'longitude': 35.860},
  ];

  static const List<Map<String, dynamic>> _mockIncidents = [
    {'incident_id': 1, 'incident_number': 'INC-1001', 'title': 'تسرب مياه في الشارع الرئيسي', 'status': 'new', 'priority': 'high', 'created_at': '2026-08-25T08:15:00'},
    {'incident_id': 2, 'incident_number': 'INC-1002', 'title': 'انقطاع مياه حي النزهة', 'status': 'in_progress', 'priority': 'critical', 'created_at': '2026-08-25T07:40:00'},
    {'incident_id': 3, 'incident_number': 'INC-1003', 'title': 'عطل في عداد المياه', 'status': 'resolved', 'priority': 'low', 'created_at': '2026-08-24T16:20:00'},
  ];

  static const List<Map<String, dynamic>> _mockDepartures = [
    {'departure_id': 1, 'employee_id': 11, 'departure_type': 'official', 'departure_time': '2026-08-25T09:00:00', 'return_time': '2026-08-25T14:00:00', 'reason': 'مهمة رسمية', 'status': 'pending', 'employee_name': 'أحمد الفني', 'employee_number': 'EMP-0011'},
    {'departure_id': 2, 'employee_id': 12, 'departure_type': 'personal', 'departure_time': '2026-08-25T12:00:00', 'return_time': '2026-08-25T13:00:00', 'reason': 'ظروف عائلية', 'status': 'approved', 'employee_name': 'خالد الموزع', 'employee_number': 'EMP-0012', 'review_note': 'موافقة'},
  ];

  static const List<Map<String, dynamic>> _mockEvals = [
    {'evaluation_id': 1, 'evaluator_id': 1, 'employee_id': 11, 'task_report_id': null, 'speed_score': 4, 'accuracy_score': 5, 'comment': 'أداء ممتاز', 'created_at': '2026-08-20T10:00:00'},
    {'evaluation_id': 2, 'evaluator_id': 1, 'employee_id': 12, 'task_report_id': null, 'speed_score': 3, 'accuracy_score': 4, 'comment': 'جيد', 'created_at': '2026-08-21T10:00:00'},
  ];

  static const List<Map<String, dynamic>> _mockIncentives = [
    {'incentive_id': 1, 'employee_id': 11, 'period_start': '2026-08-01', 'period_end': '2026-08-31', 'avg_speed': 4.2, 'avg_accuracy': 4.8, 'performance_score': 92.0, 'incentive_amount': null, 'status': 'pending'},
    {'incentive_id': 2, 'employee_id': 12, 'period_start': '2026-08-01', 'period_end': '2026-08-31', 'avg_speed': 3.8, 'avg_accuracy': 4.1, 'performance_score': 85.0, 'incentive_amount': 150.0, 'status': 'approved'},
  ];

  static Future<bool> isOnline() async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity != ConnectivityResult.none;
  }

  static Future<void> syncTelemetry(List<GpsTelemetry> telemetryList) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final data = telemetryList.map((t) => {
      'employee_id': t.employeeId,
      'latitude': t.latitude,
      'longitude': t.longitude,
      'speed': t.speed,
      'recorded_at': t.recordedAt.toIso8601String(),
    }).toList();
    await _dio.post('/gps/telemetry/batch', data: {'points': data},
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  static Future<void> syncAttendance(AttendanceLog log) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/attendance/sync', data: {'records': [log.toJson()]},
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  static Future<Map<String, dynamic>> getWorkZones(int employeeId) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _dio.get('/zones/employee/$employeeId',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data;
  }

  // ---------------- Shifts ----------------
  static Future<List<dynamic>> getShifts() async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _dio.get('/shifts',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data;
  }

  static Future<void> createShift(Map<String, dynamic> body) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/shifts', data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  static Future<void> applyShift(int shiftId) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/shifts/$shiftId/apply',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  // ---------------- Task / Daily Reports ----------------
  static Future<void> createTaskReport(Map<String, dynamic> body) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/reports/task', data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  static Future<List<dynamic>> getMyTaskReports() async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _dio.get('/reports/task/mine',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data;
  }

  // ---------------- Overtime ----------------
  static Future<List<dynamic>> getOvertime({String? from, String? to}) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final query = <String, dynamic>{};
    if (from != null) query['date_from'] = from;
    if (to != null) query['date_to'] = to;
    final response = await _dio.get('/attendance/overtime', queryParameters: query,
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data;
  }

  // ---------------- Performance Evaluations ----------------
  static Future<void> createEvaluation(Map<String, dynamic> body) async {
    if (demoMode) return;
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/evaluations', data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  static Future<List<dynamic>> getEvaluations({int? employeeId, String? periodFrom, String? periodTo}) async {
    if (demoMode) return _mockEvals;
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final query = <String, dynamic>{};
    if (employeeId != null) query['employee_id'] = employeeId;
    if (periodFrom != null) query['period_from'] = periodFrom;
    if (periodTo != null) query['period_to'] = periodTo;
    final response = await _dio.get('/evaluations', queryParameters: query,
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data['data'] as List<dynamic>? ?? [];
  }

  static Future<List<dynamic>> getMyEvaluations() async {
    if (demoMode) return _mockEvals;
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _dio.get('/evaluations/mine',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data['data'] as List<dynamic>? ?? [];
  }

  static Future<Map<String, dynamic>> getEmployeeSummary(int employeeId) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _dio.get('/evaluations/employee/$employeeId/summary',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data['data'] ?? <String, dynamic>{};
  }

  // ---------------- Incentives ----------------
  static Future<void> computeIncentive(Map<String, dynamic> body) async {
    if (demoMode) return;
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/incentives/compute', data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  static Future<List<dynamic>> getIncentives({int? employeeId}) async {
    if (demoMode) {
      if (employeeId == null) return _mockIncentives;
      return [
        {'incentive_id': 1, 'employee_id': employeeId, 'period_start': '2026-08-01', 'period_end': '2026-08-31', 'avg_speed': 4.2, 'avg_accuracy': 4.6, 'performance_score': 90.0, 'incentive_amount': null, 'status': 'pending'},
        {'incentive_id': 2, 'employee_id': employeeId, 'period_start': '2026-08-01', 'period_end': '2026-08-31', 'avg_speed': 4.0, 'avg_accuracy': 4.3, 'performance_score': 88.0, 'incentive_amount': 120.0, 'status': 'approved'},
      ];
    }
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final query = <String, dynamic>{};
    if (employeeId != null) query['employee_id'] = employeeId;
    final response = await _dio.get('/incentives', queryParameters: query,
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data['data'] as List<dynamic>? ?? [];
  }

  // ---------------- Reports (Excel) ----------------
  static Future<List<dynamic>> getAttendanceReport({
    String? date,
    int? employeeId,
    String? month,
  }) async {
    if (demoMode) return _demoAttendance(date: date, employeeId: employeeId, month: month);
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final query = <String, dynamic>{};
    if (date != null) {
      query['date_from'] = '${date}T00:00:00';
      query['date_to'] = '${date}T23:59:59';
    } else if (month != null) {
      final parts = month.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final first = DateTime(y, m, 1);
      final last = DateTime(y, m + 1, 1).subtract(const Duration(seconds: 1));
      query['date_from'] = first.toIso8601String();
      query['date_to'] = last.toIso8601String();
    }
    if (employeeId != null) query['employee_id'] = employeeId;
    final response = await _dio.get('/attendance/all', queryParameters: query,
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data['data'] as List<dynamic>? ?? [];
  }

  static List<Map<String, dynamic>> _demoAttendance({
    String? date,
    int? employeeId,
    String? month,
  }) {
    final rows = <Map<String, dynamic>>[];
    if (date != null) {
      for (final e in _mockEmployees) {
        rows.add(_demoAttendanceRow(e, date, 8, 16));
      }
    } else if (month != null) {
      final parts = month.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final list = (employeeId == null)
          ? _mockEmployees
          : _mockEmployees.where((e) => e['employee_id'] == employeeId).toList();
      for (var d = 1; d <= 12; d++) {
        final day = DateTime(y, m, d);
        if (day.weekday > 5) continue;
        final ds = '${y}-${_pad2(m)}-${_pad2(d)}';
        for (final e in list) {
          rows.add(_demoAttendanceRow(e, ds, 8, 16));
        }
      }
    }
    return rows;
  }

  static Map<String, dynamic> _demoAttendanceRow(
      Map<String, dynamic> e, String date, int h1, int h2) {
    return {
      'employee_id': e['employee_id'],
      'employee_number': e['username'],
      'full_name': e['full_name'],
      'department': e['department'],
      'role_id': 1,
      'check_in_time': '${date}T0${h1}:05:00',
      'check_out_time': '${date}T${h2}:10:00',
      'trust_status': 'valid',
      'overtime_hours': 0,
    };
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0');

  static Future<void> approveIncentive(int incentiveId, Map<String, dynamic> body) async {
    if (demoMode) return;
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/incentives/$incentiveId/approve', data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  // ---------------- Inspection Tours ----------------
  static Future<void> assignInspection(Map<String, dynamic> body) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/inspections', data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  static Future<List<dynamic>> getInspections() async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _dio.get('/inspections',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data['data'] as List<dynamic>? ?? [];
  }

  static Future<List<dynamic>> getInspectionPoints(int tourId) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _dio.get('/inspections/$tourId/points',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data['data'] as List<dynamic>? ?? [];
  }

  static Future<void> startInspection(int tourId) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/inspections/$tourId/start',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  static Future<void> addInspectionPoint(int tourId, double lat, double lng) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/inspections/$tourId/points',
      data: {'latitude': lat, 'longitude': lng},
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  static Future<void> completeInspection(int tourId) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/inspections/$tourId/complete',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  static Future<void> sendInspection(int tourId) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/inspections/$tourId/send',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  // ---------------- Live Tracking (managers) ----------------
  static Future<List<dynamic>> getLiveEmployees() async {
    if (demoMode) return _mockLive;
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _dio.get('/gps/employees/live',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data['data'] as List<dynamic>? ?? [];
  }

  // ---------------- Incidents ----------------
  static Future<void> createIncident(Map<String, dynamic> body) async {
    if (demoMode) return;
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/incidents', data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  static Future<List<dynamic>> getIncidents({String? status}) async {
    if (demoMode) return _mockIncidents;
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final query = <String, dynamic>{};
    if (status != null) query['status'] = status;
    final response = await _dio.get('/incidents', queryParameters: query,
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data['data'] as List<dynamic>? ?? [];
  }

  static Future<void> acceptIncident(int incidentId) async {
    if (demoMode) return;
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/incidents/$incidentId/accept',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  static Future<void> arriveIncident(int incidentId, double lat, double lng) async {
    if (demoMode) return;
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/incidents/$incidentId/arrive?latitude=$lat&longitude=$lng',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  static Future<void> startIncident(int incidentId) async {
    if (demoMode) return;
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/incidents/$incidentId/start',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  static Future<void> completeIncident(int incidentId) async {
    if (demoMode) return;
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/incidents/$incidentId/complete',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  // ---------------- Zones ----------------
  static Future<List<dynamic>> getZones() async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _dio.get('/zones/',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data['data'] as List<dynamic>? ?? [];
  }

  static Future<List<dynamic>> getEmployeeZones(int employeeId) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _dio.get('/zones/employee/$employeeId',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data['data'] as List<dynamic>? ?? [];
  }

  // ---------------- Employees (web monitoring) ----------------
  static Future<List<dynamic>> getEmployees() async {
    if (demoMode) return _mockEmployees;
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _dio.get('/employees/',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data['data'] as List<dynamic>? ?? [];
  }

  // ---------------- Departures ----------------
  static Future<void> createDeparture(Map<String, dynamic> body) async {
    if (demoMode) return;
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/departures', data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  static Future<List<dynamic>> getMyDepartures() async {
    if (demoMode) return _mockDepartures;
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _dio.get('/departures/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data['data'] as List<dynamic>? ?? [];
  }

  static Future<List<dynamic>> getDepartures({String? status}) async {
    if (demoMode) {
      return _mockDepartures
          .where((d) => status == null || d['status'] == status)
          .toList();
    }
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    final query = <String, dynamic>{};
    if (status != null) query['status'] = status;
    final response = await _dio.get('/departures', queryParameters: query,
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data['data'] as List<dynamic>? ?? [];
  }

  static Future<void> reviewDeparture(int id, String status, {String? note}) async {
    if (demoMode) return;
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');
    await _dio.post('/departures/$id/review',
      data: {'status': status, if (note != null) 'review_note': note},
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  }
}
