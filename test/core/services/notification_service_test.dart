import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:private_tracker_app/core/services/notification_service.dart';

class MockFlutterLocalNotificationsPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

void main() {
  group('NotificationService', () {
    late NotificationService service;
    late MockFlutterLocalNotificationsPlugin mockPlugin;

    setUp(() {
      tz.initializeTimeZones();
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      service = NotificationService(notificationsPlugin: mockPlugin);
      
      // Register fallback value for TZDateTime
      registerFallbackValue(tz.TZDateTime.now(tz.UTC));
      registerFallbackValue(const NotificationDetails());
      registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
      registerFallbackValue(DateTimeComponents.time);
    });

    test('scheduleDailyReminder calls zonedSchedule with correct parameters', () async {
      when(() => mockPlugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
      )).thenAnswer((_) async => {});

      const time = TimeOfDay(hour: 10, minute: 30);
      await service.scheduleDailyReminder(
        id: 1,
        time: time,
        title: 'Test Title',
        body: 'Test Body',
      );

      verify(() => mockPlugin.zonedSchedule(
        id: 1,
        title: 'Test Title',
        body: 'Test Body',
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      )).called(1);
    });

    test('cancelAllNotifications calls cancelAll', () async {
      when(() => mockPlugin.cancelAll()).thenAnswer((_) async => {});
      
      await service.cancelAllNotifications();
      
      verify(() => mockPlugin.cancelAll()).called(1);
    });
  });
}
