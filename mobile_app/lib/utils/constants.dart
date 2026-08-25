import '../models/employee_model.dart';

class AppConstants {
  // API
  static const String apiBaseUrl = 'https://api.yarmouk-water.jo/v1';
  static const int apiTimeoutSeconds = 15;
  static const int apiMaxRetries = 3;

  // GPS
  static const double gpsAccuracyThreshold = 15.0; // meters
  static const int gpsFreshnessThreshold = 15; // seconds
  static const double gpsDistanceFilter = 50.0; // meters
  static const int gpsTimeInterval = 30; // seconds

  // Geofence
  static const double geofenceDefaultRadius = 50.0; // meters
  static const double meterReadingRadius = 15.0; // meters
  static const List<double> geofenceRadiusOptions = [10, 15, 20, 30, 50];

  // Attendance
  static const int idleThresholdMinutes = 10;
  static const int offlineTimeoutMinutes = 30;

  // Trust Score
  static const int trustScoreValidThreshold = 80;
  static const int trustScoreReviewThreshold = 60;
  static const int trustScoreSuspiciousThreshold = 40;

  // Sync
  static const int syncRetryMaxAttempts = 5;
  static const int syncRetryBaseDelaySeconds = 2;
  static const int syncBatchSize = 100;

  // Storage
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String employeeDataKey = 'employee_data';
  static const String settingsKey = 'app_settings';

  // Notifications
  static const String notificationChannelId = 'yarmouk_location_channel';
  static const String notificationChannelName = 'Yarmouk Water Tracking';
  static const String notificationChannelDesc = 'Active field route tracking';

  // Company
  static const String companyName = 'شركة مياه اليرموك';
  static const String companyNameEn = 'Yarmouk Water Company';
}

class RoleConstants {
  static const String superAdmin = 'super_admin';
  static const String generalManager = 'general_manager';
  static const String hrManager = 'hr_manager';
  static const String branchManager = 'branch_manager';
  static const String maintenanceDirector = 'maintenance_director';
  static const String distributionDirector = 'distribution_director';
  static const String sewageDirector = 'sewage_director';
  static const String fieldSupervisor = 'field_supervisor';
  static const String officeEmployee = 'office_employee';
  static const String officeFieldEmployee = 'office_field_employee';
  static const String maintenanceTech = 'maintenance_tech';
  static const String waterDistributor = 'water_distributor';
  static const String sewageWorker = 'sewage_worker';
  static const String collector = 'collector';
  static const String gisEngineer = 'gis_engineer';
  static const String auditor = 'auditor';
  static const String readOnly = 'read_only';

  // Unified permission sets (must mirror backend permission seed)
  static const Map<String, List<String>> permissions = {
    'super_admin': ['*'],
    'general_manager': ['*'],
    'hr_manager': [
      'attendance.view', 'attendance.approve', 'attendance.edit',
      'employee.view', 'employee.create', 'employee.edit', 'employee.disable',
      'overtime.view', 'overtime.approve', 'overtime.reject',
      'report.view', 'report.export', 'shift.manage', 'shift.view',
      'evaluation.create', 'evaluation.view',
      'incentive.view', 'incentive.manage',
      'inspection.create', 'inspection.view',
      'departure.hr_review',
    ],
    'branch_manager': [
      'attendance.view', 'attendance.approve',
      'employee.view', 'employee.edit',
      'zones.*', 'incidents.*', 'gps.*', 'reports.*', 'overtime.view',
      'shift.manage', 'shift.view',
      'evaluation.create', 'evaluation.view',
      'incentive.view', 'inspection.create', 'inspection.view',
    ],
    'maintenance_director': [
      'attendance.view', 'attendance.approve', 'gps.view_live', 'gps.view_history',
      'incident.assign', 'incident.accept', 'incident.arrive', 'incident.repair',
      'incident.close', 'incident.create', 'incident.view',
      'zone.create', 'zone.edit', 'zone.assign', 'zone.delete',
      'employee.view', 'employee.edit', 'report.view', 'report.export',
      'shift.manage', 'shift.view', 'overtime.view',
      'evaluation.create', 'evaluation.view',
      'incentive.view', 'inspection.create', 'inspection.view',
    ],
    'distribution_director': [
      'attendance.view', 'attendance.approve', 'gps.view_live', 'gps.view_history', 'gps.track',
      'incident.assign', 'incident.accept', 'incident.arrive', 'incident.repair',
      'incident.close', 'incident.create', 'incident.view',
      'zone.create', 'zone.edit', 'zone.assign', 'zone.delete',
      'employee.view', 'employee.edit', 'report.view', 'report.export',
      'shift.manage', 'shift.view', 'overtime.view',
      'evaluation.create', 'evaluation.view',
      'incentive.view', 'inspection.create', 'inspection.view',
    ],
    'sewage_director': [
      'attendance.view', 'attendance.approve', 'gps.view_live', 'gps.view_history',
      'incident.assign', 'incident.accept', 'incident.arrive', 'incident.repair',
      'incident.close', 'incident.create', 'incident.view',
      'zone.create', 'zone.edit', 'zone.assign', 'zone.delete',
      'employee.view', 'employee.edit', 'report.view', 'report.export',
      'shift.manage', 'shift.view', 'overtime.view',
      'evaluation.create', 'evaluation.view',
      'incentive.view', 'inspection.create', 'inspection.view',
    ],
    'field_supervisor': [
      'incident.assign', 'incident.close', 'incident.view',
      'gps.view_live', 'gps.view_history', 'zone.view', 'attendance.view',
      'shift.view', 'report.create', 'report.view', 'overtime.view',
      'evaluation.create', 'evaluation.view',
      'incentive.view', 'inspection.create', 'inspection.view',
    ],
    'office_employee': ['attendance.checkin', 'attendance.checkout', 'attendance.view', 'shift.view', 'report.create', 'evaluation.view'],
    'office_field_employee': [
      'attendance.checkin', 'attendance.checkout', 'attendance.view', 'gps.track', 'gps.view_live',
      'incident.accept', 'incident.arrive', 'incident.repair', 'shift.view', 'report.create', 'evaluation.view',
    ],
    'maintenance_tech': [
      'attendance.checkin', 'attendance.checkout',
      'incident.accept', 'incident.arrive', 'incident.repair', 'incident.close',
      'shift.view', 'report.create', 'evaluation.view',
    ],
    'water_distributor': ['attendance.checkin', 'attendance.checkout', 'gps.track', 'shift.view', 'report.create', 'evaluation.view', 'inspection.view', 'inspection.update'],
    'sewage_worker': [
      'attendance.checkin', 'attendance.checkout',
      'incident.accept', 'incident.arrive', 'incident.repair', 'incident.close',
      'shift.view', 'report.create', 'evaluation.view',
    ],
    'collector': [
      'attendance.checkin', 'attendance.checkout',
      'collector.read_meter', 'collector.issue_bill', 'collector.view_zone',
      'shift.view', 'report.create', 'evaluation.view',
    ],
    'gis_engineer': ['zones.*', 'system.*', 'zone.view', 'attendance.view', 'report.view', 'evaluation.view'],
    'auditor': ['reports.*', 'system.*', 'attendance.view', 'gps.view_history', 'incident.view', 'employee.view', 'overtime.view', 'report.view', 'shift.view', 'evaluation.view', 'incentive.view'],
    'read_only': ['attendance.view', 'gps.view_live', 'gps.view_history', 'incident.view', 'employee.view', 'report.view', 'overtime.view', 'shift.view', 'evaluation.view', 'incentive.view'],
  };

  static bool hasPermission(int roleId, String code) {
    final roleName = roleNameFromId(roleId);
    final perms = permissions[roleName];
    if (perms == null) return false;
    if (perms.contains('*')) return true;
    if (perms.contains(code)) return true;
    // wildcard module match e.g. 'zones.*' covers 'zones.create'
    final module = code.contains('.') ? code.split('.').first + '.*' : null;
    if (module != null && perms.contains(module)) return true;
    return false;
  }
}

class IncidentStatus {
  static const String new_ = 'new';
  static const String assigned = 'assigned';
  static const String accepted = 'accepted';
  static const String enRoute = 'en_route';
  static const String arrived = 'arrived';
  static const String inProgress = 'in_progress';
  static const String waiting = 'waiting';
  static const String completed = 'completed';
  static const String verified = 'verified';
  static const String closed = 'closed';
  static const String cancelled = 'cancelled';
}

class MaintenanceSteps {
  static const String accepted = 'accepted';
  static const String arrived = 'arrived';
  static const String startRepair = 'start_repair';
  static const String completed = 'completed';
  static const String nextTarget = 'next_target';
}
