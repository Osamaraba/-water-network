-- ============================================================
-- YARMOUK WATER PLATFORM - TRIGGERS & FUNCTIONS
-- ============================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to tables
CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON employees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_work_zones_updated_at BEFORE UPDATE ON work_zones
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_attendance_logs_updated_at BEFORE UPDATE ON attendance_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_incidents_updated_at BEFORE UPDATE ON incidents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_overtime_requests_updated_at BEFORE UPDATE ON overtime_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to log attendance events
CREATE OR REPLACE FUNCTION log_attendance_event()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO attendance_events (log_id, employee_id, event_type, event_data, recorded_at)
        VALUES (NEW.log_id, NEW.employee_id, 'check_in', jsonb_build_object('location', ST_AsGeoJSON(NEW.check_in_location)::jsonb, 'accuracy', NEW.check_in_accuracy), NEW.check_in_time);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' AND NEW.check_out_time IS NOT NULL AND OLD.check_out_time IS NULL THEN
        INSERT INTO attendance_events (log_id, employee_id, event_type, event_data, recorded_at)
        VALUES (NEW.log_id, NEW.employee_id, 'check_out', jsonb_build_object('location', ST_AsGeoJSON(NEW.check_out_location)::jsonb, 'accuracy', NEW.check_out_accuracy), NEW.check_out_time);
        RETURN NEW;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_log_attendance_event AFTER INSERT OR UPDATE ON attendance_logs
    FOR EACH ROW EXECUTE FUNCTION log_attendance_event();

-- Function to log incident status changes
CREATE OR REPLACE FUNCTION log_incident_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO incident_status_history (incident_id, old_status, new_status, changed_by, created_at)
        VALUES (NEW.incident_id, OLD.status, NEW.status, NEW.updated_at, CURRENT_TIMESTAMP);
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_log_incident_status AFTER UPDATE ON incidents
    FOR EACH ROW EXECUTE FUNCTION log_incident_status_change();

-- Function to create security event for mock location
CREATE OR REPLACE FUNCTION detect_mock_location()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_mock_location_detected = TRUE THEN
        INSERT INTO security_events (employee_id, event_type, severity, description, location, created_at)
        VALUES (NEW.employee_id, 'MOCK_LOCATION', 'critical', 'Mock location detected during attendance', NEW.check_in_location, CURRENT_TIMESTAMP);
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_detect_mock_location AFTER INSERT OR UPDATE ON attendance_logs
    FOR EACH ROW WHEN (NEW.is_mock_location_detected = TRUE)
    EXECUTE FUNCTION detect_mock_location();

-- Function to update device last_seen
CREATE OR REPLACE FUNCTION update_device_last_seen()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE employee_devices SET last_seen = CURRENT_TIMESTAMP WHERE device_id = NEW.device_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_update_device_last_seen AFTER INSERT ON gps_telemetry
    FOR EACH ROW EXECUTE FUNCTION update_device_last_seen();
