from sqlalchemy import Column, Integer, String, Boolean, DateTime, Time, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.geo import point, polygon
from app.database import Base

class Employee(Base):
    __tablename__ = "employees"

    employee_id = Column(Integer, primary_key=True, index=True)
    employee_number = Column(String(50), unique=True, nullable=False, index=True)
    full_name = Column(String(100), nullable=False)
    phone = Column(String(20))
    email = Column(String(100))
    department = Column(String(50))
    branch = Column(String(50))
    role_id = Column(Integer, ForeignKey("roles.role_id"), nullable=False)
    supervisor_id = Column(Integer, ForeignKey("employees.employee_id"))
    status = Column(String(20), default="active")
    shift_start = Column(Time)
    shift_end = Column(Time)
    must_change_password = Column(Boolean, default=True)
    password_hash = Column(String(255))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    role = relationship("Role", back_populates="employees")
    devices = relationship("EmployeeDevice", back_populates="employee", cascade="all, delete-orphan")
    attendance_logs = relationship("AttendanceLog", back_populates="employee")
    gps_sessions = relationship("GpsSession", back_populates="employee")

class Role(Base):
    __tablename__ = "roles"

    role_id = Column(Integer, primary_key=True, index=True)
    role_name = Column(String(50), unique=True, nullable=False)
    role_label = Column(String(100), nullable=False)
    description = Column(Text)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    employees = relationship("Employee", back_populates="role")
    permissions = relationship("Permission", secondary="role_permissions", back_populates="roles")

class Permission(Base):
    __tablename__ = "permissions"

    permission_id = Column(Integer, primary_key=True, index=True)
    permission_code = Column(String(100), unique=True, nullable=False)
    permission_name = Column(String(100), nullable=False)
    module = Column(String(50), nullable=False)
    description = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    roles = relationship("Role", secondary="role_permissions", back_populates="permissions")

class RolePermission(Base):
    __tablename__ = "role_permissions"

    role_permission_id = Column(Integer, primary_key=True, index=True)
    role_id = Column(Integer, ForeignKey("roles.role_id", ondelete="CASCADE"), nullable=False)
    permission_id = Column(Integer, ForeignKey("permissions.permission_id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class EmployeeDevice(Base):
    __tablename__ = "employee_devices"

    device_id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"), nullable=False)
    installation_id = Column(String(100), nullable=False)
    device_uuid = Column(String(256), nullable=False)
    platform = Column(String(20), nullable=False)
    manufacturer = Column(String(50))
    model = Column(String(50))
    os_version = Column(String(30))
    app_version = Column(String(20))
    integrity_status = Column(String(20), default="unknown")
    is_primary = Column(Boolean, default=False)
    is_blocked = Column(Boolean, default=False)
    block_reason = Column(Text)
    first_seen = Column(DateTime(timezone=True), server_default=func.now())
    last_seen = Column(DateTime(timezone=True), server_default=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    employee = relationship("Employee", back_populates="devices")
