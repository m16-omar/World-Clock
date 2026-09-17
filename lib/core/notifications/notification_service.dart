import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../features/alarms/models/alarm_model.dart';
import '../timezone/timezone_database.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification tapped: ${details.payload}');
        },
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted =
            await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosImplementation = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return true;
  }

  Future<void> scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.isEnabled) {
      await cancelAlarm(alarm.id);
      return;
    }

    try {
      final loc = TimezoneDatabase.getLocation(alarm.ianaId) ?? tz.local;
      final nowInZone = tz.TZDateTime.now(loc);

      var scheduledDate = tz.TZDateTime(
        loc,
        nowInZone.year,
        nowInZone.month,
        nowInZone.day,
        alarm.hour,
        alarm.minute,
      );

      if (scheduledDate.isBefore(nowInZone)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'world_time_alarms',
        'World Time Alarms',
        channelDescription: 'Scheduled timezone and local alarms',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        playSound: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final subtitle = alarm.cityName != 'Local Time'
          ? '${alarm.cityName} time (${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')})'
          : 'Alarm ringing!';

      if (alarm.repeatDays.isNotEmpty) {
        // Repeat on scheduled days
        await _plugin.zonedSchedule(
          id: alarm.id,
          title: alarm.title.isEmpty ? 'Alarm' : alarm.title,
          body: subtitle,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'alarm_${alarm.id}',
        );
      } else {
        // One-time alarm
        await _plugin.zonedSchedule(
          id: alarm.id,
          title: alarm.title.isEmpty ? 'Alarm' : alarm.title,
          body: subtitle,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'alarm_${alarm.id}',
        );
      }
    } catch (e) {
      debugPrint('Error scheduling alarm ${alarm.id}: $e');
    }
  }

  Future<void> cancelAlarm(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Error canceling alarm $id: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }

  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'world_time_test',
      'Test Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      id: 99999,
      title: 'World Time Alarm Test',
      body: 'Your alarm notification system is active and working perfectly!',
      notificationDetails: details,
    );
  }
}
