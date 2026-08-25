import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class StatusIndicator extends StatelessWidget {
  final String status;
  final String? label;
  final double size;
  final bool showLabel;

  const StatusIndicator({
    super.key,
    required this.status,
    this.label,
    this.size = 10,
    this.showLabel = true,
  });

  Color get _color {
    switch (status.toLowerCase()) {
      case 'active':
      case 'valid':
      case 'completed':
      case 'synced':
      case 'approved':
      case 'online':
        return AppTheme.successColor;
      case 'pending':
      case 'review':
      case 'warning':
      case 'syncing':
      case 'en_route':
      case 'assigned':
        return AppTheme.warningColor;
      case 'rejected':
      case 'suspicious':
      case 'failed':
      case 'error':
      case 'offline':
      case 'blocked':
        return AppTheme.dangerColor;
      case 'in_progress':
      case 'accepted':
      case 'arrived':
        return AppTheme.infoColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _color.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        if (showLabel && label != null) ...[
          const SizedBox(width: 6),
          Text(
            label!,
            style: TextStyle(
              fontSize: 12,
              color: _color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
