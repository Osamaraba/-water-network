-- ============================================================
-- SEED: EMPLOYEES (Hierarchical: GM -> Directors -> Supervisor -> Field)
-- Default password for all: Yarmouk@2025
-- ============================================================
INSERT INTO employees (employee_number, full_name, phone, email, department, branch, role_id, supervisor_id, password_hash, status, shift_start, shift_end) VALUES
('EMP001', 'المدير العام', '0790000001', 'gm@yarmouk-water.jo', 'الإدارة', 'عجلون', 2, NULL, '$2b$12$vUM36ppKbaXIWNKwARsYn.s2QZpiQTOkr/OVCq1cKCzKF0jZdvEMC', 'active', '08:00', '16:00'),
('EMP002', 'مدير صيانة', '0790000002', 'maint.dir@yarmouk-water.jo', 'الصيانة', 'عجلون', 5, 1, '$2b$12$vUM36ppKbaXIWNKwARsYn.s2QZpiQTOkr/OVCq1cKCzKF0jZdvEMC', 'active', '08:00', '16:00'),
('EMP003', 'مدير توزيع', '0790000003', 'dist.dir@yarmouk-water.jo', 'التوزيع', 'عجلون', 6, 1, '$2b$12$vUM36ppKbaXIWNKwARsYn.s2QZpiQTOkr/OVCq1cKCzKF0jZdvEMC', 'active', '08:00', '16:00'),
('EMP004', 'مدير صرف صحي', '0790000004', 'sewage.dir@yarmouk-water.jo', 'الصرف الصحي', 'عجلون', 7, 1, '$2b$12$vUM36ppKbaXIWNKwARsYn.s2QZpiQTOkr/OVCq1cKCzKF0jZdvEMC', 'active', '08:00', '16:00'),
('EMP005', 'مشرف ميداني صيانة', '0790000005', 'maint.sup@yarmouk-water.jo', 'الصيانة', 'عجلون', 8, 2, '$2b$12$vUM36ppKbaXIWNKwARsYn.s2QZpiQTOkr/OVCq1cKCzKF0jZdvEMC', 'active', '07:00', '15:00'),
('EMP006', 'مشرف ميداني توزيع', '0790000006', 'dist.sup@yarmouk-water.jo', 'التوزيع', 'عجلون', 8, 3, '$2b$12$vUM36ppKbaXIWNKwARsYn.s2QZpiQTOkr/OVCq1cKCzKF0jZdvEMC', 'active', '07:00', '15:00'),
('EMP007', 'فني صيانة', '0790000007', 'maint1@yarmouk-water.jo', 'الصيانة', 'عجلون', 11, 5, '$2b$12$vUM36ppKbaXIWNKwARsYn.s2QZpiQTOkr/OVCq1cKCzKF0jZdvEMC', 'active', '07:00', '15:00'),
('EMP008', 'موزع مياه', '0790000008', 'dist1@yarmouk-water.jo', 'التوزيع', 'عجلون', 12, 6, '$2b$12$vUM36ppKbaXIWNKwARsYn.s2QZpiQTOkr/OVCq1cKCzKF0jZdvEMC', 'active', '06:00', '14:00'),
('EMP009', 'عامل صرف صحي', '0790000009', 'sewage1@yarmouk-water.jo', 'الصرف الصحي', 'عجلون', 13, 4, '$2b$12$vUM36ppKbaXIWNKwARsYn.s2QZpiQTOkr/OVCq1cKCzKF0jZdvEMC', 'active', '07:00', '15:00'),
('EMP010', 'موظف مكتبي', '0790000010', 'office1@yarmouk-water.jo', 'المكتب', 'عجلون', 9, 1, '$2b$12$vUM36ppKbaXIWNKwARsYn.s2QZpiQTOkr/OVCq1cKCzKF0jZdvEMC', 'active', '08:00', '16:00'),
('EMP011', 'موظف مكتب وميدان', '0790000011', 'officefield1@yarmouk-water.jo', 'المكتب', 'عجلون', 10, 1, '$2b$12$vUM36ppKbaXIWNKwARsYn.s2QZpiQTOkr/OVCq1cKCzKF0jZdvEMC', 'active', '08:00', '16:00'),
('EMP012', 'جابي', '0790000012', 'collector1@yarmouk-water.jo', 'الجباية', 'عجلون', 14, 1, '$2b$12$vUM36ppKbaXIWNKwARsYn.s2QZpiQTOkr/OVCq1cKCzKF0jZdvEMC', 'active', '08:00', '16:00'),
('EMP013', 'مهندس GIS', '0790000013', 'gis1@yarmouk-water.jo', 'GIS', 'عجلون', 15, 1, '$2b$12$vUM36ppKbaXIWNKwARsYn.s2QZpiQTOkr/OVCq1cKCzKF0jZdvEMC', 'active', '08:00', '16:00'),
('EMP014', 'مدقق', '0790000014', 'auditor1@yarmouk-water.jo', 'التدقيق', 'عجلون', 16, 1, '$2b$12$vUM36ppKbaXIWNKwARsYn.s2QZpiQTOkr/OVCq1cKCzKF0jZdvEMC', 'active', '08:00', '16:00'),
('EMP015', 'مستخدم قراءة فقط', '0790000015', 'readonly1@yarmouk-water.jo', 'الإدارة', 'عجلون', 17, 1, '$2b$12$vUM36ppKbaXIWNKwARsYn.s2QZpiQTOkr/OVCq1cKCzKF0jZdvEMC', 'active', '08:00', '16:00');
