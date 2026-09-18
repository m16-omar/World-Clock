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

  static const String alarmChannelId = 'world_time_alarm_channel_v2';
  static const String alarmChannelName = 'World Time Alarms';
  static const String alarmChannelDesc =
      'Loud alarm notifications that ring and pop on screen';

  static final Int64List _vibrationPattern =
      Int64List.fromList([0, 1000, 500, 1000, 500, 1000]);

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

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
          debugPrint('Alarm notification tapped: ${details.payload}');
        },
      );

      // Create high-priority alarm notification channel on Android (API 26+)
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final channel = AndroidNotificationChannel(
          alarmChannelId,
          alarmChannelName,
          description: alarmChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: _vibrationPattern,
          enableLights: true,
          showBadge: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );
        await androidImplementation.createNotificationChannel(channel);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  /// Requests all necessary permissions for alarms:
  /// - POST_NOTIFICATIONS on Android 13+ and iOS
  /// - SCHEDULE_EXACT_ALARM on Android 12+
  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final grantedNotification =
            await androidImplementation.requestNotificationsPermission();

        final canExact =
            await androidImplementation.canScheduleExactNotifications();
        if (canExact != true) {
          await androidImplementation.requestExactAlarmsPermission();
        }

        return grantedNotification ?? false;
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

  /// Checks if notification permissions are granted
  Future<bool> hasPermission() async {
    try {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final enabled = await androidImplementation.areNotificationsEnabled();
        return enabled ?? true;
      }
    } catch (_) {}
    return true;
  }

  Future<void> scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.isEnabled) {
      await cancelAlarm(alarm.id);
      return;
    }

    try {
      // Ensure permissions are in place
      await requestPermissions();

      // Resolve timezone location accurately
      tz.Location loc;
      if (alarm.cityName.contains('Local') || alarm.ianaId == 'UTC') {
        loc = TimezoneDatabase.getLocation(TimezoneDatabase.localIanaId) ??
            tz.local;
      } else {
        loc = TimezoneDatabase.getLocation(alarm.ianaId) ?? tz.local;
      }

      final nowInZone = tz.TZDateTime.now(loc);

      var scheduledDate = tz.TZDateTime(
        loc,
        nowInZone.year,
        nowInZone.month,
        nowInZone.day,
        alarm.hour,
        alarm.minute,
      );

      if (alarm.repeatDays.isEmpty) {
        // One-off alarm: if scheduled time today already passed, move to tomorrow
        if (scheduledDate.isBefore(nowInZone) ||
            scheduledDate.isAtSameMomentAs(nowInZone)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
      } else {
        // Repeat alarm: advance until finding the next active day that is in the future
        while (!alarm.repeatDays.contains(scheduledDate.weekday) ||
            scheduledDate.isBefore(nowInZone) ||
            scheduledDate.isAtSameMomentAs(nowInZone)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
      }

      final androidDetails = AndroidNotificationDetails(
        alarmChannelId,
        alarmChannelName,
        channelDescription: alarmChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: alarm.vibrate,
        vibrationPattern: alarm.vibrate ? _vibrationPattern : null,
        visibility: NotificationVisibility.public,
        ticker: 'Alarm: ${alarm.title.isEmpty ? "Alarm" : alarm.title}',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final title = alarm.title.isEmpty ? 'Alarm' : alarm.title;
      final timeStr =
          '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
      final subtitle = alarm.cityName != 'Local Device Time' &&
              alarm.cityName != 'Local Time'
          ? '${alarm.cityName} ($timeStr) — Alarm ringing!'
          : 'Alarm ringing ($timeStr)';

      // Determine Android exact scheduling capability safely
      var scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final canExact =
            await androidImplementation.canScheduleExactNotifications();
        if (canExact != true) {
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        }
      }

      if (alarm.repeatDays.isNotEmpty) {
        await _plugin.zonedSchedule(
          id: alarm.id,
          title: title,
          body: subtitle,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: alarm.repeatDays.length == 7
              ? DateTimeComponents.time
              : DateTimeComponents.dayOfWeekAndTime,
          payload: 'alarm_${alarm.id}',
        );
      } else {
        await _plugin.zonedSchedule(
          id: alarm.id,
          title: title,
          body: subtitle,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: scheduleMode,
          payload: 'alarm_${alarm.id}',
        );
      }
      debugPrint('Scheduled alarm ${alarm.id} at $scheduledDate in ${loc.name}');
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

  /// Triggers an immediate test alarm notification so user can verify sound, vibration and pop-up
  Future<void> showTestNotification() async {
    await requestPermissions();

    final androidDetails = AndroidNotificationDetails(
      alarmChannelId,
      alarmChannelName,
      channelDescription: alarmChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      vibrationPattern: _vibrationPattern,
      visibility: NotificationVisibility.public,
      ticker: 'Alarm Test',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      id: 99999,
      title: '⏰ World Time Alarm Test',
      body: 'Your alarm sound and heads-up banner are working perfectly!',
      notificationDetails: details,
      payload: 'alarm_test',
    );
  }
}
