import 'package:equatable/equatable.dart';

enum UserRole {
  superAdmin,
  generalManager,
  hrManager,
  branchManager,
  maintenanceDirector,
  distributionDirector,
  sewageDirector,
  fieldSupervisor,
  officeEmployee,
  officeFieldEmployee,
  maintenanceTech,
  waterDistributor,
  sewageWorker,
  collector,
  gisEngineer,
  auditor,
  readOnly,
}

const Map<int, UserRole> _roleIdToEnum = {
  1: UserRole.superAdmin,
  2: UserRole.generalManager,
  3: UserRole.hrManager,
  4: UserRole.branchManager,
  5: UserRole.maintenanceDirector,
  6: UserRole.distributionDirector,
  7: UserRole.sewageDirector,
  8: UserRole.fieldSupervisor,
  9: UserRole.officeEmployee,
  10: UserRole.officeFieldEmployee,
  11: UserRole.maintenanceTech,
  12: UserRole.waterDistributor,
  13: UserRole.sewageWorker,
  14: UserRole.collector,
  15: UserRole.gisEngineer,
  16: UserRole.auditor,
  17: UserRole.readOnly,
};

const Map<int, String> _roleIdToName = {
  1: 'super_admin',
  2: 'general_manager',
  3: 'hr_manager',
  4: 'branch_manager',
  5: 'maintenance_director',
  6: 'distribution_director',
  7: 'sewage_director',
  8: 'field_supervisor',
  9: 'office_employee',
  10: 'office_field_employee',
  11: 'maintenance_tech',
  12: 'water_distributor',
  13: 'sewage_worker',
  14: 'collector',
  15: 'gis_engineer',
  16: 'auditor',
  17: 'read_only',
};

UserRole roleFromId(int id) => _roleIdToEnum[id] ?? UserRole.officeEmployee;
String roleNameFromId(int id) => _roleIdToName[id] ?? 'office_employee';

// Field categories (anything field earns overtime after HR shift end)
const Set<int> _fieldRoleIds = {8, 10, 11, 12, 13, 14};

class Employee extends Equatable {
  final int employeeId;
  final String fullName;
  final int roleId;
  final String roleName;
  final String deviceUuid;
  final bool isActive;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? department;
  final String? branch;
  final DateTime? createdAt;

  Employee({
    required this.employeeId,
    required this.fullName,
    required this.roleId,
    String? roleName,
    required this.deviceUuid,
    this.isActive = true,
    this.email,
    this.phone,
    this.avatarUrl,
    this.department,
    this.branch,
    this.createdAt,
  }) : roleName = roleName ?? roleNameFromId(roleId);

  UserRole get role => roleFromId(roleId);
  bool get isField => _fieldRoleIds.contains(roleId);
  bool get isOffice => roleId == 9 || roleId == 10 || roleId <= 7 || roleId >= 15;

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    employeeId: json['employee_id'],
    fullName: (json['full_name'] as String?)?.trim().isNotEmpty == true
        ? (json['full_name'] as String).trim()
        : (json['username'] as String? ?? 'موظف'),
    roleId: json['role_id'] ?? 9,
    roleName: json['role_name'] ?? json['role_name'],
    deviceUuid: json['device_uuid'] ?? '',
    isActive: json['is_active'] ?? true,
    email: json['email'],
    phone: json['phone'],
    avatarUrl: json['avatar_url'],
    department: json['department'],
    branch: json['branch'],
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'employee_id': employeeId,
    'full_name': fullName,
    'role_id': roleId,
    'role_name': roleName,
    'device_uuid': deviceUuid,
    'is_active': isActive,
    'email': email,
    'phone': phone,
    'avatar_url': avatarUrl,
    'department': department,
    'branch': branch,
    'created_at': createdAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [employeeId, fullName, roleId, deviceUuid, isActive];
}
