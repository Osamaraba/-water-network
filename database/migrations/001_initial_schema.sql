-- ============================================================
-- YARMOUK WATER PLATFORM - INITIAL SCHEMA
-- PostgreSQL 15+ + PostGIS Extension
-- ============================================================

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ============================================================
-- 1. SYSTEM SETTINGS
-- ============================================================
CREATE TABLE system_settings (
    setting_id SERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value JSONB NOT NULL,
    description TEXT,
    category VARCHAR(50) DEFAULT 'general',
    is_editable BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 2. ROLES & PERMISSIONS
-- ============================================================
CREATE TABLE roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL,
    role_label VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE permissions (
    permission_id SERIAL PRIMARY KEY,
    permission_code VARCHAR(100) UNIQUE NOT NULL,
    permission_name VARCHAR(100) NOT NULL,
    module VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE role_permissions (
    role_permission_id SERIAL PRIMARY KEY,
    role_id INT NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
    permission_id INT NOT NULL REFERENCES permissions(permission_id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(role_id, permission_id)
);

-- ============================================================
-- 3. EMPLOYEES
-- ============================================================
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    employee_number VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    department VARCHAR(50),
    branch VARCHAR(50),
    role_id INT NOT NULL REFERENCES roles(role_id),
    supervisor_id INT REFERENCES employees(employee_id),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'terminated')),
    shift_start TIME,
    shift_end TIME,
    must_change_password BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 4. EMPLOYEE DEVICES
-- ============================================================
CREATE TABLE employee_devices (
    device_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    installation_id VARCHAR(100) NOT NULL,
    device_uuid VARCHAR(256) NOT NULL,
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('android', 'ios')),
    manufacturer VARCHAR(50),
    model VARCHAR(50),
    os_version VARCHAR(30),
    app_version VARCHAR(20),
    integrity_status VARCHAR(20) DEFAULT 'unknown' CHECK (integrity_status IN ('verified', 'failed', 'unknown', 'pending')),
    is_primary BOOLEAN DEFAULT FALSE,
    is_blocked BOOLEAN DEFAULT FALSE,
    block_reason TEXT,
    first_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(employee_id, device_uuid)
);

-- ============================================================
-- 5. SHIFTS
-- ============================================================
CREATE TABLE shifts (
    shift_id SERIAL PRIMARY KEY,
    shift_name VARCHAR(50) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    grace_minutes INT DEFAULT 15,
    is_night_shift BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE shift_assignments (
    assignment_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    shift_id INT NOT NULL REFERENCES shifts(shift_id) ON DELETE CASCADE,
    effective_from DATE NOT NULL,
    effective_to DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(employee_id, effective_from)
);

CREATE TABLE holidays (
    holiday_id SERIAL PRIMARY KEY,
    holiday_name VARCHAR(100) NOT NULL,
    holiday_date DATE NOT NULL,
    is_recurring BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE leave_requests (
    leave_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    leave_type VARCHAR(30) NOT NULL CHECK (leave_type IN ('annual', 'sick', 'emergency', 'unpaid', 'other')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
    approved_by INT REFERENCES employees(employee_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 6. WORK ZONES
-- ============================================================
CREATE TABLE work_zones (
    zone_id SERIAL PRIMARY KEY,
    zone_name VARCHAR(100) NOT NULL,
    zone_type VARCHAR(20) NOT NULL CHECK (zone_type IN ('radius_point', 'polygon')),
    center_point GEOMETRY(Point, 4326),
    radius_meters FLOAT,
    boundary_polygon GEOMETRY(Polygon, 4326),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_by INT REFERENCES employees(employee_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE zone_assignments (
    assignment_id SERIAL PRIMARY KEY,
    zone_id INT NOT NULL REFERENCES work_zones(zone_id) ON DELETE CASCADE,
    employee_id INT NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    assigned_from DATE NOT NULL,
    assigned_to DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(zone_id, employee_id, assigned_from)
);

-- ============================================================
-- 7. ATTENDANCE
-- ============================================================
CREATE TABLE attendance_logs (
    log_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    device_id INT REFERENCES employee_devices(device_id),
    session_id UUID DEFAULT uuid_generate_v4(),
    check_in_time TIMESTAMP WITH TIME ZONE NOT NULL,
    check_out_time TIMESTAMP WITH TIME ZONE,
    check_in_location GEOMETRY(Point, 4326) NOT NULL,
    check_out_location GEOMETRY(Point, 4326),
    check_in_accuracy FLOAT,
    check_out_accuracy FLOAT,
    check_in_image_url TEXT,
    check_out_image_url TEXT,
    is_offline_sync BOOLEAN DEFAULT FALSE,
    client_transaction_id VARCHAR(100),
    trust_score INT CHECK (trust_score BETWEEN 0 AND 100),
    trust_status VARCHAR(20) DEFAULT 'valid' CHECK (trust_status IN ('valid', 'review', 'suspicious', 'rejected')),
    trust_reasons JSONB,
    server_check_in_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    server_check_out_time TIMESTAMP WITH TIME ZONE,
    device_time_offset_seconds INT,
    is_mock_location_detected BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE attendance_events (
    event_id SERIAL PRIMARY KEY,
    log_id INT REFERENCES attendance_logs(log_id) ON DELETE CASCADE,
    employee_id INT NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB,
    location GEOMETRY(Point, 4326),
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE attendance_evidence (
    evidence_id SERIAL PRIMARY KEY,
    log_id INT NOT NULL REFERENCES attendance_logs(log_id) ON DELETE CASCADE,
    evidence_type VARCHAR(20) NOT NULL CHECK (evidence_type IN ('check_in', 'check_out')),
    image_url TEXT NOT NULL,
    image_hash VARCHAR(256) NOT NULL,
    file_size_bytes INT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 8. GPS TELEMETRY
-- ============================================================
CREATE TABLE gps_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id INT NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    device_id INT REFERENCES employee_devices(device_id),
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ended_at TIMESTAMP WITH TIME ZONE,
    start_location GEOMETRY(Point, 4326),
    end_location GEOMETRY(Point, 4326),
    total_distance_meters FLOAT DEFAULT 0,
    total_points INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE gps_telemetry (
    telemetry_id BIGSERIAL PRIMARY KEY,
    session_id UUID NOT NULL REFERENCES gps_sessions(session_id) ON DELETE CASCADE,
    employee_id INT NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    coordinates GEOMETRY(Point, 4326) NOT NULL,
    accuracy FLOAT,
    altitude FLOAT,
    speed FLOAT,
    heading FLOAT,
    battery_level INT,
    network_type VARCHAR(20),
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
    server_received_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_synced BOOLEAN DEFAULT TRUE
);

-- ============================================================
-- 9. INCIDENTS
-- ============================================================
CREATE TABLE incidents (
    incident_id SERIAL PRIMARY KEY,
    incident_number VARCHAR(50) UNIQUE NOT NULL,
    incident_type VARCHAR(50) NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    location GEOMETRY(Point, 4326),
    location_address TEXT,
    status VARCHAR(30) DEFAULT 'new' CHECK (status IN ('new', 'assigned', 'accepted', 'en_route', 'arrived', 'in_progress', 'waiting', 'completed', 'verified', 'closed', 'cancelled')),
    created_by INT NOT NULL REFERENCES employees(employee_id),
    assigned_team_id INT,
    assigned_employee_id INT REFERENCES employees(employee_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP WITH TIME ZONE,
    arrived_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    verified_at TIMESTAMP WITH TIME ZONE,
    closed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE incident_assignments (
    assignment_id SERIAL PRIMARY KEY,
    incident_id INT NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
    employee_id INT NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    assigned_by INT REFERENCES employees(employee_id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE
);

CREATE TABLE incident_status_history (
    history_id SERIAL PRIMARY KEY,
    incident_id INT NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
    old_status VARCHAR(30),
    new_status VARCHAR(30) NOT NULL,
    changed_by INT REFERENCES employees(employee_id),
    notes TEXT,
    location GEOMETRY(Point, 4326),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE incident_photos (
    photo_id SERIAL PRIMARY KEY,
    incident_id INT NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
    employee_id INT NOT NULL REFERENCES employees(employee_id),
    photo_url TEXT NOT NULL,
    photo_type VARCHAR(30) NOT NULL CHECK (photo_type IN ('arrival', 'start_repair', 'completed', 'other')),
    description TEXT,
    location GEOMETRY(Point, 4326),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 10. CUSTOMERS & METERS
-- ============================================================
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_number VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    location GEOMETRY(Point, 4326),
    zone_id INT REFERENCES work_zones(zone_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE meters (
    meter_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    meter_number VARCHAR(50) UNIQUE NOT NULL,
    meter_type VARCHAR(30) DEFAULT 'water',
    location GEOMETRY(Point, 4326),
    installation_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE meter_readings (
    reading_id SERIAL PRIMARY KEY,
    meter_id INT NOT NULL REFERENCES meters(meter_id) ON DELETE CASCADE,
    employee_id INT NOT NULL REFERENCES employees(employee_id),
    reading_value FLOAT NOT NULL,
    previous_reading FLOAT,
    consumption FLOAT,
    reading_image_url TEXT,
    location GEOMETRY(Point, 4326),
    accuracy FLOAT,
    distance_to_meter FLOAT,
    is_suspicious BOOLEAN DEFAULT FALSE,
    is_synced BOOLEAN DEFAULT TRUE,
    client_transaction_id VARCHAR(100),
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 11. OVERTIME
-- ============================================================
CREATE TABLE overtime_requests (
    request_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    attendance_log_id INT REFERENCES attendance_logs(log_id),
    incident_id INT REFERENCES incidents(incident_id),
    request_date DATE NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    hours_requested FLOAT,
    hours_approved FLOAT DEFAULT 0,
    reason TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'auto_rejected', 'cancelled')),
    rejection_reason TEXT,
    approved_by INT REFERENCES employees(employee_id),
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 12. NOTIFICATIONS
-- ============================================================
CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    severity VARCHAR(20) DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'critical')),
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 13. SYNC QUEUE
-- ============================================================
CREATE TABLE sync_queue (
    queue_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    device_id INT REFERENCES employee_devices(device_id),
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100),
    operation VARCHAR(20) NOT NULL CHECK (operation IN ('create', 'update', 'delete')),
    payload JSONB NOT NULL,
    client_transaction_id VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'syncing', 'synced', 'verified', 'failed')),
    retry_count INT DEFAULT 0,
    last_error TEXT,
    synced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 14. AUDIT LOGS
-- ============================================================
CREATE TABLE audit_logs (
    audit_id BIGSERIAL PRIMARY KEY,
    user_id INT REFERENCES employees(employee_id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100),
    old_value JSONB,
    new_value JSONB,
    ip_address INET,
    user_agent TEXT,
    device_info JSONB,
    location GEOMETRY(Point, 4326),
    request_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 15. SECURITY EVENTS
-- ============================================================
CREATE TABLE security_events (
    event_id BIGSERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id),
    device_id INT REFERENCES employee_devices(device_id),
    event_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) DEFAULT 'warning' CHECK (severity IN ('info', 'warning', 'critical')),
    description TEXT,
    evidence JSONB,
    location GEOMETRY(Point, 4326),
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_by INT REFERENCES employees(employee_id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 16. WATER NETWORK GIS
-- ============================================================
CREATE TABLE network_pipes (
    pipe_id SERIAL PRIMARY KEY,
    pipe_number VARCHAR(50) UNIQUE,
    pipe_type VARCHAR(30),
    diameter_mm FLOAT,
    material VARCHAR(30),
    installation_date DATE,
    geometry GEOMETRY(LineString, 4326),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE network_valves (
    valve_id SERIAL PRIMARY KEY,
    valve_number VARCHAR(50) UNIQUE,
    valve_type VARCHAR(30),
    diameter_mm FLOAT,
    status VARCHAR(20) DEFAULT 'operational',
    location GEOMETRY(Point, 4326),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE network_assets (
    asset_id SERIAL PRIMARY KEY,
    asset_type VARCHAR(30) NOT NULL CHECK (asset_type IN ('pump', 'reservoir', 'tank', 'meter_station', 'other')),
    asset_number VARCHAR(50) UNIQUE,
    asset_name VARCHAR(100),
    location GEOMETRY(Point, 4326),
    capacity FLOAT,
    status VARCHAR(20) DEFAULT 'operational',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
