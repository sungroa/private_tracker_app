import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/core/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../domain/cycle_calculator_clock_test.dart'; // Reuse MockClock

class MockNotificationsPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

void main() {
  late NotificationService service;
  late MockNotificationsPlugin mockPlugin;
  late MockClock mockClock;

  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(tz.TZDateTime.now(tz.UTC));
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
    registerFallbackValue(DateTimeComponents.time);
  });

  setUp(() {
    mockPlugin = MockNotificationsPlugin();
    mockClock = MockClock(DateTime.utc(2026, 5, 15));
    service = NotificationService(
      notificationsPlugin: mockPlugin,
      clock: mockClock,
    );

    when(() => mockPlugin.zonedSchedule(
      id: any(named: 'id'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      scheduledDate: any(named: 'scheduledDate'),
      notificationDetails: any(named: 'notificationDetails'),
      androidScheduleMode: any(named: 'androidScheduleMode'),
      matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
    )).thenAnswer((_) async {});
  });

  group('NotificationService Tests', () {
    test('scheduleDailyReminder should schedule for today if time is in the future', () async {
      // Mock current time: 2026-05-15 10:00:00
      mockClock.setNow(DateTime.utc(2026, 5, 15, 10, 0, 0));
      
      // Schedule for 11:00:00 today
      await service.scheduleDailyReminder(
        id: 1,
        time: const TimeOfDay(hour: 11, minute: 0),
        title: 'Title',
        body: 'Body',
      );

      final captured = verify(() => mockPlugin.zonedSchedule(
        id: 1,
        title: 'Title',
        body: 'Body',
        scheduledDate: captureAny(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        matchDateTimeComponents: DateTimeComponents.time,
      )).captured;

      final scheduledDate = captured.first as tz.TZDateTime;
      expect(scheduledDate.year, 2026);
      expect(scheduledDate.month, 5);
      expect(scheduledDate.day, 15);
      expect(scheduledDate.hour, 11);
    });

    test('scheduleDailyReminder should schedule for tomorrow if time is in the past', () async {
      // Mock current time: 2026-05-15 10:00:00
      mockClock.setNow(DateTime.utc(2026, 5, 15, 10, 0, 0));
      
      // Schedule for 09:00:00 (past)
      await service.scheduleDailyReminder(
        id: 1,
        time: const TimeOfDay(hour: 9, minute: 0),
        title: 'Title',
        body: 'Body',
      );

      final captured = verify(() => mockPlugin.zonedSchedule(
        id: 1,
        title: 'Title',
        body: 'Body',
        scheduledDate: captureAny(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        matchDateTimeComponents: DateTimeComponents.time,
      )).captured;

      final scheduledDate = captured.first as tz.TZDateTime;
      expect(scheduledDate.year, 2026);
      expect(scheduledDate.month, 5);
      expect(scheduledDate.day, 16); // Tomorrow
      expect(scheduledDate.hour, 9);
    });

    test('scheduleSingleNotification should not schedule if date is in the past', () async {
      mockClock.setNow(DateTime.utc(2026, 5, 15, 10, 0, 0));
      
      await service.scheduleSingleNotification(
        id: 1,
        date: DateTime.utc(2026, 5, 14), // Yesterday
        time: const TimeOfDay(hour: 10, minute: 0),
        title: 'Title',
        body: 'Body',
      );

      verifyNever(() => mockPlugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
      ));
    });

    test('cancelAllNotifications calls cancelAll', () async {
      when(() => mockPlugin.cancelAll()).thenAnswer((_) async => {});
      await service.cancelAllNotifications();
      verify(() => mockPlugin.cancelAll()).called(1);
    });
  });
}
