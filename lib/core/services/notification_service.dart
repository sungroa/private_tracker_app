import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io' show Platform;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  NotificationService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notificationsPlugin = notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  /// Initializes the notification service.
  Future<void> initialize() async {
    debugPrint('[PrivacyTracker.Notifications] Initializing NotificationService...');
    // Initialize timezone data
    tz.initializeTimeZones();
    
    // Get device timezone
    try {
      final dynamic locationData = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = locationData is String ? locationData : locationData.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('[PrivacyTracker.Notifications] Timezone set to: $timeZoneName');
    } catch (e) {
      debugPrint('[PrivacyTracker.Notifications] Timezone fallback to UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('ic_notification');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, 
      requestBadgePermission: false, 
      requestSoundPermission: false,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[PrivacyTracker.Notifications] Notification response: ${response.payload}');
      },
    );

    // (W10) Explicitly create the channel to ensure it appears in Android settings
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'daily_reminder_channel',
          'Daily Reminders',
          description: 'Recurring daily logging reminders',
          importance: Importance.max,
        ),
      );
      debugPrint('[PrivacyTracker.Notifications] Notification channel created.');
    }
    debugPrint('[PrivacyTracker.Notifications] Initialization complete.');
  }

  /// Schedules a recurring daily notification.
  Future<void> scheduleDailyReminder({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the scheduled time is in the past, move it to the next day
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Recurring daily logging reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // This makes it recur daily
    );
  }

  /// Cancels all pending notifications.
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Requests permissions (for iOS and Android 13+).
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? androidGranted = await androidPlugin?.requestNotificationsPermission();
      
      // On Android < 13, requestNotificationsPermission returns null (implicitly granted).
      return (androidGranted ?? true);
    } else if (Platform.isIOS) {
      final bool? iosGranted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return iosGranted ?? false;
    }
    
    return false;
  }
}
