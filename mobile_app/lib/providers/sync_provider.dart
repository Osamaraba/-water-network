import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/sync_service.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class SyncStart extends SyncEvent {}

class SyncForceSync extends SyncEvent {}

class SyncStatusCheck extends SyncEvent {}

abstract class SyncState extends Equatable {
  const SyncState();
  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {}

class SyncInProgress extends SyncState {
  final int pendingItems;
  final int totalItems;
  final String currentItem;
  const SyncInProgress({
    required this.pendingItems,
    required this.totalItems,
    required this.currentItem,
  });
  @override
  List<Object?> get props => [pendingItems, totalItems, currentItem];
}

class SyncCompleted extends SyncState {
  final int syncedCount;
  final int failedCount;
  const SyncCompleted({required this.syncedCount, required this.failedCount});
  @override
  List<Object?> get props => [syncedCount, failedCount];
}

class SyncError extends SyncState {
  final String message;
  const SyncError(this.message);
  @override
  List<Object?> get props => [message];
}

class SyncOffline extends SyncState {
  final int pendingCount;
  const SyncOffline(this.pendingCount);
  @override
  List<Object?> get props => [pendingCount];
}

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncService _syncService = SyncService();

  SyncBloc() : super(SyncInitial()) {
    on<SyncStart>(_onStart);
    on<SyncForceSync>(_onForceSync);
    on<SyncStatusCheck>(_onStatusCheck);
  }

  Future<void> _onStart(
    SyncStart event,
    Emitter<SyncState> emit,
  ) async {
    await _syncService.initializeAutoSync(
      onProgress: (pending, total, current) {
        emit(SyncInProgress(
          pendingItems: pending,
          totalItems: total,
          currentItem: current,
        ));
      },
      onCompleted: (synced, failed) {
        emit(SyncCompleted(syncedCount: synced, failedCount: failed));
      },
      onError: (error) {
        emit(SyncError(error));
      },
    );
  }

  Future<void> _onForceSync(
    SyncForceSync event,
    Emitter<SyncState> emit,
  ) async {
    emit(const SyncInProgress(pendingItems: 0, totalItems: 0, currentItem: 'جاري المزامنة...'));
    try {
      final result = await _syncService.forceSyncAll();
      emit(SyncCompleted(
        syncedCount: result['synced'] ?? 0,
        failedCount: result['failed'] ?? 0,
      ));
    } catch (e) {
      emit(SyncError('فشل المزامنة: $e'));
    }
  }

  Future<void> _onStatusCheck(
    SyncStatusCheck event,
    Emitter<SyncState> emit,
  ) async {
    final pending = await _syncService.getPendingCount();
    final isOnline = await _syncService.isOnline();

    if (!isOnline) {
      emit(SyncOffline(pending));
    } else if (pending > 0) {
      emit(SyncInProgress(
        pendingItems: pending,
        totalItems: pending,
        currentItem: 'في الانتظار',
      ));
    } else {
      emit(const SyncCompleted(syncedCount: 0, failedCount: 0));
    }
  }
}
