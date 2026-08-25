import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:hive/hive.dart';
import '../models/attendance_model.dart';
import '../models/gps_telemetry_model.dart';

class LocalStorageService {
  static Database? _database;
  static Box? _hiveBox;

  static Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'yarmouk_water.db');
    _database = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute(
        'CREATE TABLE attendance_logs ('
        'log_id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'employee_id INTEGER NOT NULL,'
        'check_in_time TEXT NOT NULL,'
        'check_out_time TEXT,'
        'check_in_lat REAL NOT NULL,'
        'check_in_lng REAL NOT NULL,'
        'check_out_lat REAL,'
        'check_out_lng REAL,'
        'check_in_image_path TEXT,'
        'check_out_image_path TEXT,'
        'is_offline_sync INTEGER DEFAULT 0,'
        'overtime_approved_hours REAL DEFAULT 0.0,'
        'is_mock_location_detected INTEGER,'
        'gps_accuracy_meters REAL,'
        'image_hash TEXT,'
        'transaction_id TEXT)'
      );
      await db.execute(
        'CREATE TABLE gps_telemetry ('
        'telemetry_id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'employee_id INTEGER NOT NULL,'
        'latitude REAL NOT NULL,'
        'longitude REAL NOT NULL,'
        'speed REAL,'
        'recorded_at TEXT NOT NULL,'
        'is_synced INTEGER DEFAULT 0)'
      );
      await db.execute('CREATE INDEX idx_telemetry_employee ON gps_telemetry(employee_id)');
      await db.execute('CREATE INDEX idx_telemetry_synced ON gps_telemetry(is_synced)');
    });
    _hiveBox = await Hive.openBox('yarmouk_settings');
  }

  static Future<int> saveAttendance(AttendanceLog log) async {
    final db = _database!;
    return await db.insert('attendance_logs', {
      'employee_id': log.employeeId,
      'check_in_time': log.checkInTime.toIso8601String(),
      'check_out_time': log.checkOutTime?.toIso8601String(),
      'check_in_lat': log.checkInLat,
      'check_in_lng': log.checkInLng,
      'check_out_lat': log.checkOutLat,
      'check_out_lng': log.checkOutLng,
      'check_in_image_path': log.checkInImagePath,
      'check_out_image_path': log.checkOutImagePath,
      'is_offline_sync': log.isOfflineSync ? 1 : 0,
      'overtime_approved_hours': log.overtimeApprovedHours,
      'is_mock_location_detected': log.isMockLocationDetected == true ? 1 : 0,
      'gps_accuracy_meters': log.gpsAccuracyMeters,
      'image_hash': log.imageHash,
      'transaction_id': log.transactionId,
    });
  }

  static Future<int> updateCheckOut(int logId, AttendanceLog log) async {
    final db = _database!;
    return await db.update('attendance_logs', {
      'check_out_time': log.checkOutTime?.toIso8601String(),
      'check_out_lat': log.checkOutLat,
      'check_out_lng': log.checkOutLng,
      'check_out_image_path': log.checkOutImagePath,
      'is_offline_sync': 0,
    }, where: 'log_id = ?', whereArgs: [logId]);
  }

  static Future<List<AttendanceLog>> getPendingAttendance() async {
    final db = _database!;
    final maps = await db.query('attendance_logs', where: 'is_offline_sync = ?', whereArgs: [0]);
    return maps.map((m) => AttendanceLog.fromJson({
      'log_id': m['log_id'],
      'employee_id': m['employee_id'],
      'check_in_time': m['check_in_time'],
      'check_out_time': m['check_out_time'],
      'check_in_lat': m['check_in_lat'],
      'check_in_lng': m['check_in_lng'],
      'check_out_lat': m['check_out_lat'],
      'check_out_lng': m['check_out_lng'],
      'check_in_image_path': m['check_in_image_path'],
      'check_out_image_path': m['check_out_image_path'],
      'is_offline_sync': m['is_offline_sync'] == 1,
      'overtime_approved_hours': m['overtime_approved_hours'],
      'is_mock_location_detected': m['is_mock_location_detected'] == 1,
      'gps_accuracy_meters': m['gps_accuracy_meters'],
      'image_hash': m['image_hash'],
      'transaction_id': m['transaction_id'],
    })).toList();
  }

  static Future<void> markAttendanceSynced(int logId) async {
    final db = _database!;
    await db.update('attendance_logs', {'is_offline_sync': 1}, where: 'log_id = ?', whereArgs: [logId]);
  }

  static Future<int> saveTelemetry(GpsTelemetry telemetry) async {
    final db = _database!;
    return await db.insert('gps_telemetry', {
      'employee_id': telemetry.employeeId,
      'latitude': telemetry.latitude,
      'longitude': telemetry.longitude,
      'speed': telemetry.speed,
      'recorded_at': telemetry.recordedAt.toIso8601String(),
      'is_synced': telemetry.isSynced ? 1 : 0,
    });
  }

  static Future<List<GpsTelemetry>> getPendingTelemetry() async {
    final db = _database!;
    final maps = await db.query('gps_telemetry', where: 'is_synced = ?', whereArgs: [0], limit: 100);
    return maps.map((m) => GpsTelemetry.fromJson({
      'telemetry_id': m['telemetry_id'],
      'employee_id': m['employee_id'],
      'latitude': m['latitude'],
      'longitude': m['longitude'],
      'speed': m['speed'],
      'recorded_at': m['recorded_at'],
      'is_synced': m['is_synced'] == 1,
    })).toList();
  }

  static Future<void> markTelemetrySynced(int telemetryId) async {
    final db = _database!;
    await db.update('gps_telemetry', {'is_synced': 1}, where: 'telemetry_id = ?', whereArgs: [telemetryId]);
  }

  static Future<void> setSetting(String key, dynamic value) async {
    await _hiveBox?.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return _hiveBox?.get(key, defaultValue: defaultValue);
  }
}
