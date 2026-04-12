import '../usecases/sync_data_use_case.dart';
import 'cloud_sync_interface.dart';

/// Orchestrates the synchronization between local data and the cloud provider.
/// 
/// This coordinator acts as a high-level facade for the UI, delegating the 
/// actual synchronization logic to [SyncDataUseCase].
class CloudSyncCoordinator {
  final SyncDataUseCase _syncUseCase;

  CloudSyncCoordinator({
    required CloudSyncInterface cloudSync,
    required SyncDataUseCase syncUseCase,
  }) : _syncUseCase = syncUseCase;

  /// Performs a full synchronization cycle.
  /// 
  /// Delegates orchestration to [_syncUseCase].
  Future<void> sync({bool forceUpload = false}) async {
    // Current V2 implementation uses SyncDataUseCase for all sync logic
    await _syncUseCase.execute();
  }
}
