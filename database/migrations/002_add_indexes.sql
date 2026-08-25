-- ============================================================
-- YARMOUK WATER PLATFORM - INDEXES & CONSTRAINTS
-- ============================================================

-- Employees indexes
CREATE INDEX idx_employees_role ON employees(role_id);
CREATE INDEX idx_employees_supervisor ON employees(supervisor_id);
CREATE INDEX idx_employees_status ON employees(status);
CREATE INDEX idx_employees_department ON employees(department);

-- Employee devices indexes
CREATE INDEX idx_devices_employee ON employee_devices(employee_id);
CREATE INDEX idx_devices_uuid ON employee_devices(device_uuid);
CREATE INDEX idx_devices_blocked ON employee_devices(is_blocked) WHERE is_blocked = TRUE;

-- Work zones spatial indexes
CREATE INDEX idx_zones_center ON work_zones USING GIST(center_point);
CREATE INDEX idx_zones_boundary ON work_zones USING GIST(boundary_polygon);
CREATE INDEX idx_zones_active ON work_zones(is_active);

-- Zone assignments indexes
CREATE INDEX idx_zone_assignments_zone ON zone_assignments(zone_id);
CREATE INDEX idx_zone_assignments_employee ON zone_assignments(employee_id);
CREATE INDEX idx_zone_assignments_dates ON zone_assignments(assigned_from, assigned_to);

-- Attendance indexes
CREATE INDEX idx_attendance_employee ON attendance_logs(employee_id);
CREATE INDEX idx_attendance_checkin_time ON attendance_logs(check_in_time);
CREATE INDEX idx_attendance_session ON attendance_logs(session_id);
CREATE INDEX idx_attendance_location ON attendance_logs USING GIST(check_in_location);
CREATE INDEX idx_attendance_trust ON attendance_logs(trust_status);
CREATE INDEX idx_attendance_offline ON attendance_logs(is_offline_sync) WHERE is_offline_sync = TRUE;
CREATE INDEX idx_attendance_transaction ON attendance_logs(client_transaction_id);

-- Attendance events indexes
CREATE INDEX idx_attendance_events_log ON attendance_events(log_id);
CREATE INDEX idx_attendance_events_employee ON attendance_events(employee_id);
CREATE INDEX idx_attendance_events_type ON attendance_events(event_type);

-- GPS sessions indexes
CREATE INDEX idx_gps_sessions_employee ON gps_sessions(employee_id);
CREATE INDEX idx_gps_sessions_active ON gps_sessions(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_gps_sessions_started ON gps_sessions(started_at);

-- GPS telemetry indexes
CREATE INDEX idx_gps_telemetry_session ON gps_telemetry(session_id);
CREATE INDEX idx_gps_telemetry_employee ON gps_telemetry(employee_id);
CREATE INDEX idx_gps_telemetry_coordinates ON gps_telemetry USING GIST(coordinates);
CREATE INDEX idx_gps_telemetry_recorded ON gps_telemetry(recorded_at);
CREATE INDEX idx_gps_telemetry_synced ON gps_telemetry(is_synced) WHERE is_synced = FALSE;

-- Incidents indexes
CREATE INDEX idx_incidents_status ON incidents(status);
CREATE INDEX idx_incidents_assigned ON incidents(assigned_employee_id);
CREATE INDEX idx_incidents_location ON incidents USING GIST(location);
CREATE INDEX idx_incidents_created ON incidents(created_at);
CREATE INDEX idx_incidents_priority ON incidents(priority);

-- Incident status history indexes
CREATE INDEX idx_incident_history_incident ON incident_status_history(incident_id);
CREATE INDEX idx_incident_history_created ON incident_status_history(created_at);

-- Customers & meters indexes
CREATE INDEX idx_customers_zone ON customers(zone_id);
CREATE INDEX idx_customers_location ON customers USING GIST(location);
CREATE INDEX idx_meters_customer ON meters(customer_id);
CREATE INDEX idx_meters_location ON meters USING GIST(location);
CREATE INDEX idx_meter_readings_meter ON meter_readings(meter_id);
CREATE INDEX idx_meter_readings_employee ON meter_readings(employee_id);
CREATE INDEX idx_meter_readings_synced ON meter_readings(is_synced) WHERE is_synced = FALSE;

-- Overtime indexes
CREATE INDEX idx_overtime_employee ON overtime_requests(employee_id);
CREATE INDEX idx_overtime_status ON overtime_requests(status);
CREATE INDEX idx_overtime_date ON overtime_requests(request_date);

-- Notifications indexes
CREATE INDEX idx_notifications_employee ON notifications(employee_id);
CREATE INDEX idx_notifications_unread ON notifications(is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_type ON notifications(notification_type);

-- Sync queue indexes
CREATE INDEX idx_sync_queue_employee ON sync_queue(employee_id);
CREATE INDEX idx_sync_queue_status ON sync_queue(status);
CREATE INDEX idx_sync_queue_transaction ON sync_queue(client_transaction_id);

-- Audit logs indexes
CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_action ON audit_logs(action);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_created ON audit_logs(created_at);
CREATE INDEX idx_audit_request ON audit_logs(request_id);

-- Security events indexes
CREATE INDEX idx_security_employee ON security_events(employee_id);
CREATE INDEX idx_security_type ON security_events(event_type);
CREATE INDEX idx_security_severity ON security_events(severity);
CREATE INDEX idx_security_unresolved ON security_events(is_resolved) WHERE is_resolved = FALSE;
CREATE INDEX idx_security_created ON security_events(created_at);

-- Network GIS indexes
CREATE INDEX idx_pipes_geometry ON network_pipes USING GIST(geometry);
CREATE INDEX idx_valves_location ON network_valves USING GIST(location);
CREATE INDEX idx_assets_location ON network_assets USING GIST(location);

-- Full text search indexes
CREATE INDEX idx_employees_name_trgm ON employees USING gin(full_name gin_trgm_ops);
CREATE INDEX idx_customers_name_trgm ON customers USING gin(full_name gin_trgm_ops);

-- Foreign key constraints (additional)
ALTER TABLE employees ADD CONSTRAINT fk_employees_role FOREIGN KEY (role_id) REFERENCES roles(role_id);
ALTER TABLE employees ADD CONSTRAINT fk_employees_supervisor FOREIGN KEY (supervisor_id) REFERENCES employees(employee_id);
ALTER TABLE incidents ADD CONSTRAINT fk_incidents_assigned FOREIGN KEY (assigned_employee_id) REFERENCES employees(employee_id);
