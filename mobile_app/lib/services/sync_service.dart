import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_storage_service.dart';
import 'api_service.dart';

class SyncService {
  Function(int, int, String)? _onProgress;
  Function(int, int)? _onCompleted;
  Function(String)? _onError;

  Future<void> initializeAutoSync({
    Function(int, int, String)? onProgress,
    Function(int, int)? onCompleted,
    Function(String)? onError,
  }) async {
    _onProgress = onProgress;
    _onCompleted = onCompleted;
    _onError = onError;
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) await _performSync();
    });
  }

  Future<Map<String, int>> forceSyncAll() async => await _performSync();

  Future<Map<String, int>> _performSync() async {
    int synced = 0, failed = 0;
    try {
      final pendingAttendance = await LocalStorageService.getPendingAttendance();
      _onProgress?.call(0, pendingAttendance.length, 'جاري مزامنة سجلات الحضور...');
      for (final log in pendingAttendance) {
        try {
          await ApiService.syncAttendance(log);
          await LocalStorageService.markAttendanceSynced(log.logId!);
          synced++;
        } catch (e) { failed++; }
      }
      final pendingTelemetry = await LocalStorageService.getPendingTelemetry();
      _onProgress?.call(synced, pendingTelemetry.length, 'جاري مزامنة بيانات الموقع...');
      if (pendingTelemetry.isNotEmpty) {
        try {
          await ApiService.syncTelemetry(pendingTelemetry);
          for (final t in pendingTelemetry) {
            await LocalStorageService.markTelemetrySynced(t.telemetryId!);
          }
          synced += pendingTelemetry.length;
        } catch (e) { failed += pendingTelemetry.length; }
      }
      _onCompleted?.call(synced, failed);
    } catch (e) { _onError?.call(e.toString()); }
    return {'synced': synced, 'failed': failed};
  }

  Future<int> getPendingCount() async {
    final attendance = await LocalStorageService.getPendingAttendance();
    final telemetry = await LocalStorageService.getPendingTelemetry();
    return attendance.length + telemetry.length;
  }

  Future<bool> isOnline() async => await ApiService.isOnline();
}
