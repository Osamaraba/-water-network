import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/gps_telemetry_model.dart';
import 'local_storage_service.dart';
import 'api_service.dart';

class LocationService {
  StreamSubscription<Position>? _positionStream;
  Timer? _syncTimer;
  int? _currentEmployeeId;

  Future<void> startTracking({
    required int employeeId,
    required Function(Position) onLocationUpdate,
  }) async {
    _currentEmployeeId = employeeId;

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('تم رفض إذن الموقع');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('إذن الموقع مرفوض نهائياً. يرجى تفعيله من الإعدادات.');
    }

    // Start foreground service
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundServiceStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'yarmouk_location_channel',
        initialNotificationTitle: 'نظام مياه اليرموك',
        initialNotificationContent: 'تتبع المسار النشط',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onBackgroundServiceStart,
        onBackground: onIosBackground,
      ),
    );
    await service.startService();

    // Start position stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 50, // Every 50 meters
      ),
    ).listen((position) async {
      onLocationUpdate(position);
      await _saveTelemetry(position);
    });

    // Periodic sync timer (every 30 seconds)
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _syncPendingTelemetry();
    });
  }

  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _syncTimer?.cancel();

    final service = FlutterBackgroundService();
    service.invoke('stopService');

    _currentEmployeeId = null;
  }

  Future<void> _saveTelemetry(Position position) async {
    if (_currentEmployeeId == null) return;

    final telemetry = GpsTelemetry(
      employeeId: _currentEmployeeId!,
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed,
      recordedAt: DateTime.now(),
      isSynced: false,
    );

    await LocalStorageService.saveTelemetry(telemetry);
  }

  Future<void> _syncPendingTelemetry() async {
    final pending = await LocalStorageService.getPendingTelemetry();
    if (pending.isEmpty) return;

    try {
      await ApiService.syncTelemetry(pending);
      for (final t in pending) {
        await LocalStorageService.markTelemetrySynced(t.telemetryId!);
      }
    } catch (_) {
      // Will retry on next cycle
    }
  }

  static void onBackgroundServiceStart(ServiceInstance service) async {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }
}
