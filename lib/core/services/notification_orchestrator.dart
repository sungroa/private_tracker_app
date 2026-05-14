import 'package:flutter/material.dart';
import '../../domain/models/trends.dart';
import 'notification_service.dart';
import 'preferences_service.dart';

/// Orchestrates complex, data-driven notifications based on cycle predictions.
/// 
/// Following "Technical Excellence" principles, this decouples notification 
/// scheduling logic from both the domain model and the UI layer.
class NotificationOrchestrator {
  final NotificationService _notificationService;
  final PreferencesService _prefs;

  NotificationOrchestrator({
    required NotificationService notificationService,
    required PreferencesService preferencesService,
  })  : _notificationService = notificationService,
        _prefs = preferencesService;

  /// Recalculates and reschedules all prediction-based notifications.
  /// 
  /// This should be called whenever [TrendData] is updated or notification 
  /// preferences are changed.
  Future<void> updateScheduledReminders(TrendData? trends) async {
    if (trends == null) {
      debugPrint('[PrivacyTracker.Notifications] Orchestrator: No trend data, skipping updates.');
      return;
    }

    // --- Period Reminder ---
    final bool periodEnabled = await _prefs.isPeriodReminderEnabled();
    if (periodEnabled && trends.predictedNextPeriod != null) {
      final int offset = await _prefs.getPeriodReminderOffset();
      final TimeOfDay time = await _prefs.getPeriodReminderTime();
      final DateTime targetDate = trends.predictedNextPeriod!.subtract(Duration(days: offset));
      
      debugPrint('[PrivacyTracker.Notifications] Orchestrator: Scheduling period reminder for ${targetDate.toIso8601String()} at ${time.format}');
      
      await _notificationService.scheduleSingleNotification(
        id: NotificationService.periodReminderId,
        date: targetDate,
        time: time,
        title: 'Period Starting Soon',
        body: 'Your period is predicted to start in $offset day${offset > 1 ? 's' : ''}.',
      );
    } else {
      debugPrint('[PrivacyTracker.Notifications] Orchestrator: Period reminder disabled or no prediction, cancelling.');
      await _notificationService.cancelNotification(NotificationService.periodReminderId);
    }

    // --- Fertility Reminder ---
    final bool fertilityEnabled = await _prefs.isFertilityReminderEnabled();
    if (fertilityEnabled && trends.predictedFertilityDates.isNotEmpty) {
      final int offset = await _prefs.getFertilityReminderOffset();
      final TimeOfDay time = await _prefs.getFertilityReminderTime();
      // Fertility window is a list, take the first day
      final DateTime fertilityStart = trends.predictedFertilityDates.first;
      final DateTime targetDate = fertilityStart.subtract(Duration(days: offset));

      debugPrint('[PrivacyTracker.Notifications] Orchestrator: Scheduling fertility reminder for ${targetDate.toIso8601String()} at ${time.format}');

      await _notificationService.scheduleSingleNotification(
        id: NotificationService.fertilityReminderId,
        date: targetDate,
        time: time,
        title: 'Fertility Window Approaching',
        body: 'Your fertile window is predicted to start in $offset day${offset > 1 ? 's' : ''}.',
      );
    } else {
      debugPrint('[PrivacyTracker.Notifications] Orchestrator: Fertility reminder disabled or no prediction, cancelling.');
      await _notificationService.cancelNotification(NotificationService.fertilityReminderId);
    }
  }
}
