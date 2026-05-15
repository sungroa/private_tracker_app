import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/core/services/notification_orchestrator.dart';
import 'package:private_tracker_app/core/services/notification_service.dart';
import 'package:private_tracker_app/core/services/preferences_service.dart';
import 'package:private_tracker_app/domain/models/trends.dart';

class MockNotificationService extends Mock implements NotificationService {}
class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  late NotificationOrchestrator orchestrator;
  late MockNotificationService mockNotificationService;
  late MockPreferencesService mockPrefs;

  setUpAll(() {
    registerFallbackValue(const TimeOfDay(hour: 0, minute: 0));
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockNotificationService = MockNotificationService();
    mockPrefs = MockPreferencesService();
    orchestrator = NotificationOrchestrator(
      notificationService: mockNotificationService,
      preferencesService: mockPrefs,
    );

    // Default mock behavior
    when(() => mockNotificationService.scheduleSingleNotification(
      id: any(named: 'id'),
      date: any(named: 'date'),
      time: any(named: 'time'),
      title: any(named: 'title'),
      body: any(named: 'body'),
    )).thenAnswer((_) async {});
    
    when(() => mockNotificationService.cancelNotification(any())).thenAnswer((_) async {});
  });

  group('NotificationOrchestrator Tests', () {
    test('updateScheduledReminders should schedule period reminder if enabled', () async {
      final trends = TrendData(
        averageCycleLength: 28,
        averagePeriodDuration: 5,
        topSymptoms: [],
        moodHistory: [],
        predictedNextPeriod: DateTime(2026, 5, 20),
        predictedFertilityDates: [],
      );

      when(() => mockPrefs.isPeriodReminderEnabled()).thenAnswer((_) async => true);
      when(() => mockPrefs.getPeriodReminderOffset()).thenAnswer((_) async => 2);
      when(() => mockPrefs.getPeriodReminderTime()).thenAnswer((_) async => const TimeOfDay(hour: 9, minute: 0));
      when(() => mockPrefs.isFertilityReminderEnabled()).thenAnswer((_) async => false);

      await orchestrator.updateScheduledReminders(trends);

      verify(() => mockNotificationService.scheduleSingleNotification(
        id: NotificationService.periodReminderId,
        date: DateTime(2026, 5, 18), // 20 - 2
        time: const TimeOfDay(hour: 9, minute: 0),
        title: any(named: 'title'),
        body: any(named: 'body'),
      )).called(1);
    });

    test('updateScheduledReminders should cancel reminders if disabled', () async {
      final trends = TrendData(
        averageCycleLength: 28,
        averagePeriodDuration: 5,
        topSymptoms: [],
        moodHistory: [],
        predictedNextPeriod: DateTime(2026, 5, 20),
        predictedFertilityDates: [],
      );

      when(() => mockPrefs.isPeriodReminderEnabled()).thenAnswer((_) async => false);
      when(() => mockPrefs.isFertilityReminderEnabled()).thenAnswer((_) async => false);

      await orchestrator.updateScheduledReminders(trends);

      verify(() => mockNotificationService.cancelNotification(NotificationService.periodReminderId)).called(1);
      verify(() => mockNotificationService.cancelNotification(NotificationService.fertilityReminderId)).called(1);
    });
  });
}
