-- ============================================================
-- SEED: WORK ZONES (Ajloun Governorate Sample)
-- ============================================================
INSERT INTO work_zones (zone_name, zone_type, center_point, radius_meters, description, is_active, created_by) VALUES
('مقر الإدارة - عجلون', 'radius_point', ST_SetSRID(ST_MakePoint(35.7523, 32.3325), 4326), 50, 'Main office building', TRUE, 7),
('منطقة الجباية - وسط المدينة', 'polygon', NULL, NULL, 'Collector zone A', TRUE, 7),
('منطقة الصيانة - الشمال', 'radius_point', ST_SetSRID(ST_MakePoint(35.7623, 32.3425), 4326), 500, 'Maintenance area north', TRUE, 7),
('منطقة التوزيع - الجنوب', 'radius_point', ST_SetSRID(ST_MakePoint(35.7423, 32.3225), 4326), 1000, 'Distribution area south', TRUE, 7);

-- Add polygon for zone 2
UPDATE work_zones SET boundary_polygon = ST_SetSRID(ST_GeomFromText('POLYGON((35.748 32.335, 35.758 32.335, 35.758 32.340, 35.748 32.340, 35.748 32.335))'), 4326) WHERE zone_id = 2;

-- Assign zones to employees
INSERT INTO zone_assignments (zone_id, employee_id, assigned_from, assigned_to) VALUES
(1, 5, '2026-01-01', NULL),
(2, 3, '2026-01-01', NULL),
(3, 1, '2026-01-01', NULL),
(3, 2, '2026-01-01', NULL),
(4, 4, '2026-01-01', NULL);
