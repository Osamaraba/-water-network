import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../models/attendance_model.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/sync_provider.dart';
import '../services/local_storage_service.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/attendance_card.dart';
import '../widgets/status_indicator.dart';
import 'evidence_screen.dart';
import 'task_report_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = false;
  bool _hasActiveSession = false;
  AttendanceLog? _activeLog;
  List<AttendanceLog> _history = [];

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
    _loadHistory();
  }

  Future<void> _checkActiveSession() async {
    final pending = await LocalStorageService.getPendingAttendance();
    for (final log in pending) {
      if (log.checkOutTime == null) {
        setState(() {
          _hasActiveSession = true;
          _activeLog = log;
        });
        return;
      }
    }
  }

  Future<void> _loadHistory() async {
    final history = await LocalStorageService.getPendingAttendance();
    setState(() => _history = history.where((l) => l.checkOutTime != null).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الحضور والانصراف')),
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, locationState) {
          final isInsideGeofence = locationState is LocationTracking && locationState.isInsideGeofence;
          final isMockLocation = locationState is LocationTracking && locationState.isMockLocation;
          final accuracy = locationState is LocationTracking ? locationState.accuracy : null;

          return Column(
            children: [
              _buildStatusCard(isInsideGeofence, isMockLocation, accuracy),
              const SizedBox(height: 8),
              _buildActionButton(isInsideGeofence, isMockLocation, accuracy),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('السجل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              Expanded(
                child: _history.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _history.length,
                        itemBuilder: (context, index) => AttendanceCard(
                          log: _history[index],
                          onTap: () => _showLogDetails(_history[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) return const SizedBox.shrink();
          if (!RoleConstants.hasPermission(state.employee.roleId, 'report.create')) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TaskReportScreen(logId: _activeLog?.logId)),
            ),
            icon: const Icon(Icons.assignment_turned_in),
            label: const Text('تقرير إنجاز'),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(bool isInsideGeofence, bool isMockLocation, double? accuracy) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: isMockLocation
          ? AppTheme.dangerColor.withOpacity(0.05)
          : isInsideGeofence
              ? AppTheme.successColor.withOpacity(0.05)
              : AppTheme.warningColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusIndicator(
                  status: isMockLocation
                      ? 'error'
                      : isInsideGeofence
                          ? 'valid'
                          : 'warning',
                  label: isMockLocation
                      ? 'موقع مزيف مكتشف!'
                      : isInsideGeofence
                          ? 'داخل المنطقة المصرح بها'
                          : 'خارج المنطقة',
                  size: 12,
                ),
                if (accuracy != null)
                  Text(
                    'الدقة: ${accuracy.toStringAsFixed(1)}م',
                    style: TextStyle(
                      fontSize: 12,
                      color: accuracy <= AppConstants.gpsAccuracyThreshold
                          ? AppTheme.successColor
                          : AppTheme.dangerColor,
                    ),
                  ),
              ],
            ),
            if (_hasActiveSession && _activeLog != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('جلسة العمل النشطة', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            'منذ ${Helpers.formatTime(_activeLog!.checkInTime)}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Helpers.formatDuration(DateTime.now().difference(_activeLog!.checkInTime)),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isInsideGeofence, bool isMockLocation, double? accuracy) {
    final canCheckIn = isInsideGeofence && !isMockLocation && (accuracy ?? 999) <= AppConstants.gpsAccuracyThreshold;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: canCheckIn ? (_hasActiveSession ? _checkOut : _checkIn) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _hasActiveSession ? AppTheme.dangerColor : AppTheme.successColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_hasActiveSession ? Icons.logout : Icons.login),
                    const SizedBox(width: 8),
                    Text(
                      _hasActiveSession ? 'تسجيل خروج' : 'تسجيل دخول',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('لا يوجد سجل حضور', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
        ],
      ),
    );
  }

  Future<void> _checkIn() async {
    setState(() => _isLoading = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final log = AttendanceLog(
        employeeId: authState.employee.employeeId,
        checkInTime: DateTime.now(),
        checkInLat: position.latitude,
        checkInLng: position.longitude,
        isOfflineSync: !(await ApiService.isOnline()),
        transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      );

      final logId = await LocalStorageService.saveAttendance(log);

      // Start GPS tracking
      context.read<LocationBloc>().add(LocationStartTracking(authState.employee.employeeId));

      // Navigate to evidence screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EvidenceScreen(
              logId: logId,
              isCheckIn: true,
              latitude: position.latitude,
              longitude: position.longitude,
            ),
          ),
        );
      }

      setState(() {
        _hasActiveSession = true;
        _activeLog = log.copyWith(logId: logId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.dangerColor),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkOut() async {
    setState(() => _isLoading = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      if (_activeLog?.logId == null) return;

      final updatedLog = _activeLog!.copyWith(
        checkOutTime: DateTime.now(),
        checkOutLat: position.latitude,
        checkOutLng: position.longitude,
      );

      await LocalStorageService.updateCheckOut(_activeLog!.logId!, updatedLog);

      // Stop GPS tracking
      context.read<LocationBloc>().add(LocationStopTracking());

      // Navigate to evidence screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EvidenceScreen(
              logId: _activeLog!.logId!,
              isCheckIn: false,
              latitude: position.latitude,
              longitude: position.longitude,
            ),
          ),
        );
      }

      setState(() {
        _hasActiveSession = false;
        _activeLog = null;
      });

      await _loadHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.dangerColor),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showLogDetails(AttendanceLog log) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تفاصيل السجل #${log.logId}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _buildDetailRow('معرف المعاملة', log.transactionId ?? '-'),
            _buildDetailRow('وقت الدخول', Helpers.formatDateTime(log.checkInTime)),
            _buildDetailRow('وقت الخروج', log.checkOutTime != null ? Helpers.formatDateTime(log.checkOutTime!) : '-'),
            _buildDetailRow('الموقع', '${log.checkInLat.toStringAsFixed(6)}, ${log.checkInLng.toStringAsFixed(6)}'),
            _buildDetailRow('درجة الثقة', '${log.trustScore ?? '-'}'),
            _buildDetailRow('الحالة', Helpers.getTrustStatusLabel(log.trustStatus ?? 'valid')),
            _buildDetailRow('العمل الإضافي', '${(log.overtimeHours ?? 0).toStringAsFixed(2)} ساعة'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
