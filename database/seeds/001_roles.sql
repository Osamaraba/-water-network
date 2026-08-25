-- ============================================================
-- SEED: ROLES (with explicit IDs for stable references)
-- ============================================================
INSERT INTO roles (role_id, role_name, role_label, description) VALUES
(1, 'super_admin', 'مدير النظام', 'Full system access and administration'),
(2, 'general_manager', 'المدير العام', 'Top executive; oversees all departments and directors'),
(3, 'hr_manager', 'مدير الموارد البشرية', 'Manages employees, attendance, and overtime'),
(4, 'branch_manager', 'مدير الفرع', 'Manages branch operations and field teams'),
(5, 'maintenance_director', 'مدير صيانة', 'Head of maintenance department; permissions derived to his team'),
(6, 'distribution_director', 'مدير توزيع', 'Head of water distribution department'),
(7, 'sewage_director', 'مدير صرف صحي', 'Head of sewage/cleaning department'),
(8, 'field_supervisor', 'مشرف ميداني', 'Supervises field teams and incidents'),
(9, 'office_employee', 'موظف مكتبي', 'Office-only employee (no field operations)'),
(10, 'office_field_employee', 'موظف مكتب وميدان', 'Office employee who also performs field tasks'),
(11, 'maintenance_tech', 'فني صيانة', 'Field maintenance technician'),
(12, 'water_distributor', 'موزع مياه', 'Field water distribution worker'),
(13, 'sewage_worker', 'عامل صرف صحي', 'Field sewage/network cleaning worker'),
(14, 'collector', 'جابي', 'Collects meter readings and issues bills'),
(15, 'gis_engineer', 'مهندس GIS', 'Manages GIS data and network assets'),
(16, 'auditor', 'مدقق', 'Read-only access to audit and reports'),
(17, 'read_only', 'قراءة فقط', 'View-only access to dashboard');

-- Reset sequence so future inserts continue after 17
SELECT setval(pg_get_serial_sequence('roles', 'role_id'), 17, true);
