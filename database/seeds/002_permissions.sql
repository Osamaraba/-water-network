-- ============================================================
-- SEED: PERMISSIONS + ROLE ASSIGNMENTS
-- ============================================================
INSERT INTO permissions (permission_code, permission_name, module, description) VALUES
-- Attendance
('attendance.checkin', 'تسجيل دخول', 'attendance', 'Check in to work'),
('attendance.checkout', 'تسجيل خروج', 'attendance', 'Check out from work'),
('attendance.view', 'عرض الحضور', 'attendance', 'View attendance records'),
('attendance.edit', 'تعديل الحضور', 'attendance', 'Edit attendance records'),
('attendance.approve', 'اعتماد الحضور', 'attendance', 'Approve attendance records'),
-- GPS
('gps.view_live', 'عرض الموقع المباشر', 'gps', 'View live employee locations'),
('gps.view_history', 'عرض سجل المسارات', 'gps', 'View historical GPS routes'),
('gps.track', 'تتبع الموقع', 'gps', 'Enable GPS tracking'),
-- Incidents
('incident.create', 'إنشاء حادث', 'incidents', 'Create new incident'),
('incident.assign', 'تعيين حادث', 'incidents', 'Assign incident to employee'),
('incident.accept', 'قبول حادث', 'incidents', 'Accept assigned incident'),
('incident.arrive', 'تأكيد الوصول', 'incidents', 'Confirm arrival at incident site'),
('incident.repair', 'بدء الإصلاح', 'incidents', 'Start repair work'),
('incident.close', 'إغلاق حادث', 'incidents', 'Close completed incident'),
-- Collectors
('collector.read_meter', 'قراءة عداد', 'collectors', 'Record meter reading'),
('collector.issue_bill', 'إصدار فاتورة', 'collectors', 'Issue bill to customer'),
('collector.view_zone', 'عرض المنطقة', 'collectors', 'View assigned collection zone'),
-- Zones
('zone.create', 'إنشاء منطقة', 'zones', 'Create work zone'),
('zone.edit', 'تعديل منطقة', 'zones', 'Edit work zone'),
('zone.delete', 'حذف منطقة', 'zones', 'Delete work zone'),
('zone.assign', 'تعيين منطقة', 'zones', 'Assign zone to employee'),
-- Employees
('employee.create', 'إنشاء موظف', 'employees', 'Create new employee'),
('employee.edit', 'تعديل موظف', 'employees', 'Edit employee details'),
('employee.disable', 'تعطيل موظف', 'employees', 'Disable employee account'),
('employee.view', 'عرض موظف', 'employees', 'View employee details'),
-- Overtime
('overtime.request', 'طلب إضافي', 'overtime', 'Request overtime'),
('overtime.approve', 'اعتماد إضافي', 'overtime', 'Approve overtime request'),
('overtime.reject', 'رفض إضافي', 'overtime', 'Reject overtime request'),
-- Reports
('report.view', 'عرض تقرير', 'reports', 'View reports'),
('report.export', 'تصدير تقرير', 'reports', 'Export reports'),
-- System
('system.settings', 'إعدادات النظام', 'system', 'Manage system settings'),
('system.audit', 'سجل التدقيق', 'system', 'View audit logs'),
    ('system.security', 'الأمان', 'system', 'View security events'),
-- Shifts
    ('shift.manage', 'إدارة الورديات', 'shifts', 'Create/edit shifts per team'),
    ('shift.view', 'عرض الورديات', 'shifts', 'View shift schedules'),
-- Reports (task completion)
    ('report.create', 'إنشاء تقرير مهمة', 'reports', 'Submit daily task completion report'),
    ('report.view', 'عرض التقارير', 'reports', 'View task completion reports'),
-- Overtime
    ('overtime.view', 'عرض العمل الإضافي', 'overtime', 'View computed overtime');

-- ============================================================
-- ROLE -> PERMISSION ASSIGNMENTS (by explicit role_id)
-- ============================================================
-- 1 Super Admin: all
INSERT INTO role_permissions (role_id, permission_id)
SELECT 1, permission_id FROM permissions;

-- 2 General Manager: all (sees/approves across all departments)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 2, permission_id FROM permissions;

-- 3 HR Manager: attendance, employees, overtime, reports
INSERT INTO role_permissions (role_id, permission_id)
SELECT 3, permission_id FROM permissions WHERE module IN ('attendance', 'employees', 'overtime', 'reports', 'shifts');

-- 4 Branch Manager: zones, incidents, employees, reports, gps
INSERT INTO role_permissions (role_id, permission_id)
SELECT 4, permission_id FROM permissions WHERE module IN ('zones', 'incidents', 'employees', 'reports', 'gps', 'shifts', 'overtime');

-- 5 Maintenance Director: his department + incidents/gps/zones
INSERT INTO role_permissions (role_id, permission_id)
SELECT 5, permission_id FROM permissions WHERE permission_code IN (
  'attendance.view', 'attendance.approve',
  'gps.view_live', 'gps.view_history',
  'incident.assign', 'incident.accept', 'incident.arrive', 'incident.repair', 'incident.close', 'incident.create',
  'zone.create', 'zone.edit', 'zone.assign', 'zone.delete',
  'employee.view', 'employee.edit',
  'report.view', 'report.export',
  'shift.manage', 'shift.view', 'overtime.view'
);

-- 6 Distribution Director
INSERT INTO role_permissions (role_id, permission_id)
SELECT 6, permission_id FROM permissions WHERE permission_code IN (
  'attendance.view', 'attendance.approve',
  'gps.view_live', 'gps.view_history', 'gps.track',
  'incident.assign', 'incident.accept', 'incident.arrive', 'incident.repair', 'incident.close', 'incident.create',
  'zone.create', 'zone.edit', 'zone.assign', 'zone.delete',
  'employee.view', 'employee.edit',
  'report.view', 'report.export',
  'shift.manage', 'shift.view', 'overtime.view'
);

-- 7 Sewage Director
INSERT INTO role_permissions (role_id, permission_id)
SELECT 7, permission_id FROM permissions WHERE permission_code IN (
  'attendance.view', 'attendance.approve',
  'gps.view_live', 'gps.view_history',
  'incident.assign', 'incident.accept', 'incident.arrive', 'incident.repair', 'incident.close', 'incident.create',
  'zone.create', 'zone.edit', 'zone.assign', 'zone.delete',
  'employee.view', 'employee.edit',
  'report.view', 'report.export',
  'shift.manage', 'shift.view', 'overtime.view'
);

-- 8 Field Supervisor: incidents, gps, zones (supervision)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 8, permission_id FROM permissions WHERE permission_code IN (
  'incident.assign', 'incident.close', 'incident.view',
  'gps.view_live', 'gps.view_history',
  'zone.view' , 'attendance.view',
  'shift.view', 'report.create', 'report.view', 'overtime.view'
);

-- 9 Office Employee (office only)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 9, permission_id FROM permissions WHERE permission_code IN (
  'attendance.checkin', 'attendance.checkout', 'attendance.view',
  'shift.view', 'report.create'
);

-- 10 Office + Field Employee
INSERT INTO role_permissions (role_id, permission_id)
SELECT 10, permission_id FROM permissions WHERE permission_code IN (
  'attendance.checkin', 'attendance.checkout', 'attendance.view',
  'gps.track', 'gps.view_live',
  'incident.accept', 'incident.arrive', 'incident.repair',
  'shift.view', 'report.create'
);

-- 11 Maintenance Tech (field)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 11, permission_id FROM permissions WHERE permission_code IN (
  'attendance.checkin', 'attendance.checkout',
  'incident.accept', 'incident.arrive', 'incident.repair', 'incident.close',
  'shift.view', 'report.create'
);

-- 12 Water Distributor (field)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 12, permission_id FROM permissions WHERE permission_code IN (
  'attendance.checkin', 'attendance.checkout', 'gps.track',
  'shift.view', 'report.create'
);

-- 13 Sewage Worker (field)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 13, permission_id FROM permissions WHERE permission_code IN (
  'attendance.checkin', 'attendance.checkout',
  'incident.accept', 'incident.arrive', 'incident.repair', 'incident.close',
  'shift.view', 'report.create'
);

-- 14 Collector
INSERT INTO role_permissions (role_id, permission_id)
SELECT 14, permission_id FROM permissions WHERE permission_code IN (
  'attendance.checkin', 'attendance.checkout',
  'collector.read_meter', 'collector.issue_bill', 'collector.view_zone',
  'shift.view', 'report.create'
);

-- 15 GIS Engineer
INSERT INTO role_permissions (role_id, permission_id)
SELECT 15, permission_id FROM permissions WHERE module IN ('zones', 'system') OR permission_code LIKE 'zone.%';

-- 16 Auditor
INSERT INTO role_permissions (role_id, permission_id)
SELECT 16, permission_id FROM permissions WHERE module IN ('reports', 'system', 'overtime')
  OR permission_code IN ('attendance.view', 'gps.view_history', 'incident.view' , 'employee.view');

-- 17 Read Only
INSERT INTO role_permissions (role_id, permission_id)
SELECT 17, permission_id FROM permissions WHERE permission_code LIKE '%.view%';
