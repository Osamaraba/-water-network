-- ============================================================
-- SEED: SYSTEM SETTINGS
-- ============================================================
INSERT INTO system_settings (setting_key, setting_value, description, category) VALUES
('gps.accuracy_threshold', '{"value": 15, "unit": "meters"}', 'Maximum acceptable GPS accuracy', 'gps'),
('gps.freshness_threshold', '{"value": 15, "unit": "seconds"}', 'Maximum acceptable GPS location age', 'gps'),
('gps.distance_filter', '{"value": 50, "unit": "meters"}', 'Distance filter for GPS tracking', 'gps'),
('gps.time_interval', '{"value": 30, "unit": "seconds"}', 'Time interval for GPS tracking', 'gps'),
('geofence.default_radius', '{"value": 50, "unit": "meters"}', 'Default geofence radius', 'geofence'),
('geofence.radius_options', '{"values": [10, 15, 20, 30, 50]}', 'Available geofence radius options', 'geofence'),
('meter.reading_radius', '{"value": 15, "unit": "meters"}', 'Maximum distance for meter reading', 'collectors'),
('attendance.idle_threshold', '{"value": 10, "unit": "minutes"}', 'Idle time threshold for alerts', 'attendance'),
('attendance.offline_timeout', '{"value": 30, "unit": "minutes"}', 'Offline timeout threshold', 'attendance'),
('security.mock_location_action', '{"action": "flag"}', 'Action on mock location detection', 'security'),
('security.clock_tamper_action', '{"action": "flag"}', 'Action on clock tampering detection', 'security'),
('overtime.auto_approve_threshold', '{"value": 2, "unit": "hours"}', 'Auto-approve overtime threshold', 'overtime'),
('company.name', '{"value": "شركة مياه اليرموك"}', 'Company name', 'general'),
('company.logo_url', '{"value": "/assets/logo.png"}', 'Company logo URL', 'general');
