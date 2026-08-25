-- ============================================================
-- YARMOUK WATER PLATFORM - MIGRATION 002
-- Shifts per team, attendance overtime, task completion reports
-- ============================================================

-- 1. Extend shifts with department (team) + created_by
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS department VARCHAR(50);
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS created_by INT REFERENCES employees(employee_id);

-- 2. Computed overtime hours on attendance
ALTER TABLE attendance_logs ADD COLUMN IF NOT EXISTS overtime_hours FLOAT DEFAULT 0;

-- 3. Task completion / daily work reports
CREATE TABLE IF NOT EXISTS task_reports (
    report_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    incident_id INT REFERENCES incidents(incident_id) ON DELETE CASCADE,
    log_id INT REFERENCES attendance_logs(log_id) ON DELETE SET NULL,
    report_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'submitted' CHECK (status IN ('submitted', 'reviewed', 'approved', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS task_report_items (
    item_id SERIAL PRIMARY KEY,
    report_id INT NOT NULL REFERENCES task_reports(report_id) ON DELETE CASCADE,
    work_description TEXT NOT NULL,
    work_date DATE NOT NULL,
    work_time TIME NOT NULL,
    quantity FLOAT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_task_reports_employee ON task_reports(employee_id);
CREATE INDEX IF NOT EXISTS idx_task_reports_date ON task_reports(report_date);
CREATE INDEX IF NOT EXISTS idx_task_report_items_report ON task_report_items(report_id);
