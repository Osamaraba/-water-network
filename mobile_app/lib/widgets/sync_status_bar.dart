import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/sync_provider.dart';
import '../utils/app_theme.dart';

class SyncStatusBar extends StatelessWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        if (state is SyncInProgress) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.infoColor.withOpacity(0.1),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.infoColor),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.currentItem,
                    style: const TextStyle(fontSize: 12, color: AppTheme.infoColor),
                  ),
                ),
                Text(
                  '${state.pendingItems}/${state.totalItems}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.infoColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        if (state is SyncOffline) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.warningColor.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, size: 16, color: AppTheme.warningColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'وضع عدم الاتصال - ${state.pendingCount} عنصر في الانتظار',
                    style: const TextStyle(fontSize: 12, color: AppTheme.warningColor),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is SyncCompleted && (state.syncedCount > 0 || state.failedCount > 0)) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.successColor.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: AppTheme.successColor),
                const SizedBox(width: 10),
                Text(
                  'تمت المزامنة: ${state.syncedCount} نجح | ${state.failedCount} فشل',
                  style: const TextStyle(fontSize: 12, color: AppTheme.successColor),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
