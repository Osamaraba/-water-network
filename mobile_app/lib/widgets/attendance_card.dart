import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';
import 'status_indicator.dart';

class AttendanceCard extends StatelessWidget {
  final AttendanceLog log;
  final VoidCallback? onTap;

  const AttendanceCard({super.key, required this.log, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasCheckout = log.checkOutTime != null;
    final duration = hasCheckout
        ? log.checkOutTime!.difference(log.checkInTime)
        : DateTime.now().difference(log.checkInTime);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Helpers.formatDate(log.checkInTime),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  StatusIndicator(
                    status: log.trustStatus ?? 'valid',
                    label: Helpers.getTrustStatusLabel(log.trustStatus ?? 'valid'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTimeColumn('الدخول', log.checkInTime, AppTheme.successColor),
                  const SizedBox(width: 24),
                  _buildTimeColumn(
                    'الخروج',
                    log.checkOutTime,
                    hasCheckout ? AppTheme.dangerColor : AppTheme.textDisabled,
                  ),
                  const SizedBox(width: 24),
                  _buildTimeColumn(
                    'المدة',
                    null,
                    AppTheme.primaryColor,
                    customText: Helpers.formatDuration(duration),
                  ),
                ],
              ),
              if (log.isOfflineSync) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.offline_bolt, size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      'تمت المزامنة من وضع عدم الاتصال',
                      style: TextStyle(fontSize: 11, color: Colors.orange[700]),
                    ),
                  ],
                ),
              ],
              if (log.trustScore != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'درجة الثقة: ${log.trustScore}',
                      style: TextStyle(
                        fontSize: 12,
                        color: log.trustScore! >= 80
                            ? AppTheme.successColor
                            : log.trustScore! >= 60
                                ? AppTheme.warningColor
                                : AppTheme.dangerColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeColumn(String label, DateTime? time, Color color, {String? customText}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            customText ?? (time != null ? Helpers.formatTime(time) : '--:--:--'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: time != null ? color : AppTheme.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
