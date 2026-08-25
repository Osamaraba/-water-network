import 'package:flutter_background_service/flutter_background_service.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  // Background entry point. Live telemetry is driven from the foreground
  // tracking service; this keeps the isolate alive when backgrounded.
}

class BackgroundService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Future<void> initialize() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'yarmouk_tracking',
        initialNotificationTitle: 'Yarmouk Water',
        initialNotificationContent: 'جاري تتبع الموقع',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  static Future<bool> start() => _service.startService();
  static void stop() {
    _service.invoke("stopService");
  }
  static FlutterBackgroundService get instance => _service;
}
