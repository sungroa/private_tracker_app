import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/storage/encrypted_storage_service.dart';
import '../../presentation/providers/cycle_provider.dart';
import '../../presentation/providers/symptom_provider.dart';
import '../../presentation/providers/tag_provider.dart';
import '../../presentation/providers/cloud_sync_provider.dart';
import '../utils/security_logger.dart';
import '../services/notification_service.dart';
import 'package:provider/provider.dart';

/// Service responsible for coordinated application initialization.
/// 
/// [AppInitializer] follows "Zero Technical Debt" by:
/// 1. Orchestrating async startup tasks outside the UI tree.
/// 2. Ensuring thread-safe initialization of storage and providers.
/// 3. Providing a unified hook for app-wide data warm-up.
class AppInitializer {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Orchestrates all startup tasks.
  /// 
  /// This should be called after successful authentication.
  Future<void> initialize(BuildContext context, {String? basePath}) async {
    if (_isInitialized) return;

    try {
      SecurityLogger.info("Starting orchestrated initialization...");

      // 1. Initialize core storage
      // This handles Hive registration, key retrieval, and box opening.
      await context.read<EncryptedStorageService>().initialize(basePath: basePath);

      if (!context.mounted) return;

      // 2. Parallel warm-up of essential providers
      // We use unawaited/concurrent triggers where possible to minimize startup delay.
      await Future.wait([
        context.read<CycleProvider>().initialize(),
        context.read<SymptomProvider>().initialize(),
        context.read<TagProvider>().initialize(),
        context.read<NotificationService>().initialize(),
      ]);

      if (!context.mounted) return;

      // 3. Trigger auto-sync if cloud is enabled
      final cloudSync = context.read<CloudSyncProvider>();
      await cloudSync.init();
      if (cloudSync.isCloudEnabled) {
        unawaited(cloudSync.sync());
      }

      _isInitialized = true;
      SecurityLogger.logEvent("Application initialized successfully");
    } catch (e, stack) {
      SecurityLogger.logError("AppInitializer failed", error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Reset initialization state (useful for logout/account wipe).
  void reset() {
    _isInitialized = false;
  }
}
